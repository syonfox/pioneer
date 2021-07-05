// Copyright © 2008-2021 Pioneer Developers. See AUTHORS.txt for details
// Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

#include "PiGuiRenderer.h"

#include "graphics/Graphics.h"
#include "graphics/Material.h"
#include "graphics/RenderState.h"
#include "graphics/Texture.h"
#include "graphics/Types.h"
#include "graphics/VertexBuffer.h"

#include "imgui/imgui.h"
#define IMGUI_DEFINE_MATH_OPERATORS
#include "imgui/imgui_internal.h"

using namespace PiGui;

size_t InstanceRenderer::s_textureName = Graphics::Renderer::GetName("texture0");
size_t InstanceRenderer::s_vertexDepthName = Graphics::Renderer::GetName("vertexDepth");

InstanceRenderer::InstanceRenderer(Graphics::Renderer *r) :
	m_renderer(r)
{}

void InstanceRenderer::Initialize()
{
	Graphics::VertexBufferDesc vbd;
	vbd.attrib[0] = { Graphics::ATTRIB_POSITION2D, Graphics::ATTRIB_FORMAT_FLOAT2, offsetof(ImDrawVert, pos) };
	vbd.attrib[1] = { Graphics::ATTRIB_UV0, Graphics::ATTRIB_FORMAT_FLOAT2, offsetof(ImDrawVert, uv) };
	vbd.attrib[2] = { Graphics::ATTRIB_DIFFUSE, Graphics::ATTRIB_FORMAT_UBYTE4, offsetof(ImDrawVert, col) };
	vbd.numVertices = 0;
	vbd.stride = sizeof(ImDrawVert);
	vbd.usage = Graphics::BUFFER_USAGE_DYNAMIC;

	m_vtxBuffer.reset(m_renderer->CreateVertexBuffer(vbd));
	m_idxBuffer.reset(m_renderer->CreateIndexBuffer(0, Graphics::BUFFER_USAGE_DYNAMIC, Graphics::INDEX_BUFFER_16BIT));

	Graphics::RenderStateDesc rsd;
	rsd.blendMode = Graphics::BLEND_ALPHA;
	rsd.cullMode = Graphics::CULL_NONE;
	rsd.depthTest = true;
	rsd.depthWrite = false;
	rsd.scissorTest = true;

	Graphics::MaterialDescriptor mDesc;
	mDesc.textures = 1;
	mDesc.alphaTest = 1;

	m_material.reset(m_renderer->CreateMaterial("ui", mDesc, rsd));

	CreateFontsTexture();
}

void InstanceRenderer::Shutdown()
{
	if (m_fontsTexture)
		DestroyFontsTexture();

	m_vtxBuffer.reset();
	m_idxBuffer.reset();
	m_material.reset();
}

void InstanceRenderer::RenderDrawData(ImDrawData *draw_data)
{
	Graphics::Renderer::StateTicket st(m_renderer);

	ImGuiIO &io = ImGui::GetIO();
	int fb_width = (int)(draw_data->DisplaySize.x * io.DisplayFramebufferScale.x);
	int fb_height = (int)(draw_data->DisplaySize.y * io.DisplayFramebufferScale.y);
	if (fb_width <= 0 || fb_height <= 0)
		return;

	draw_data->ScaleClipRects(io.DisplayFramebufferScale);

	float L = draw_data->DisplayPos.x;
	float R = draw_data->DisplayPos.x + draw_data->DisplaySize.x;
	float T = draw_data->DisplayPos.y;
	float B = draw_data->DisplayPos.y + draw_data->DisplaySize.y;
	m_renderer->SetTransform(matrix4x4f::Identity());
	m_renderer->SetProjection(matrix4x4f::OrthoFrustum(L, R, B, T, -1.0, 0.0));

	// we're going to throw all of the vertex and index data straight to the GPU
	// in a single buffer for each, right before we begin executing commands.
	// This should make optimal use of transfer resources.
	std::vector<ImDrawVert> vtxStagingBuffer;
	vtxStagingBuffer.reserve(1024);
	std::vector<ImDrawIdx> idxStagingBuffer;
	idxStagingBuffer.reserve(1024);

	for (int n = 0; n < draw_data->CmdListsCount; n++) {
		const ImDrawList *cmd_list = draw_data->CmdLists[n];

		// coalesce vertex and index data into a single buffer upload
		auto &imVtxBuffer = cmd_list->VtxBuffer;
		size_t vtxOffset = vtxStagingBuffer.size();
		vtxStagingBuffer.reserve(vtxOffset + imVtxBuffer.Size);

		auto &imIdxBuffer = cmd_list->IdxBuffer;
		size_t idxOffset = idxStagingBuffer.size();
		idxStagingBuffer.reserve(idxOffset + imIdxBuffer.Size);

		// write this command list's data to the tail of the staging array
		vtxStagingBuffer.insert(vtxStagingBuffer.end(), imVtxBuffer.Data, imVtxBuffer.Data + imVtxBuffer.Size);
		idxStagingBuffer.insert(idxStagingBuffer.end(), imIdxBuffer.Data, imIdxBuffer.Data + imIdxBuffer.Size);

		// Generate renderer commands for each draw command in the command buffer list.
		for (int cmd_i = 0; cmd_i < cmd_list->CmdBuffer.Size; cmd_i++) {
			const ImDrawCmd *pcmd = &cmd_list->CmdBuffer[cmd_i];
			if (pcmd->UserCallback)
				pcmd->UserCallback(cmd_list, pcmd);
			else {
				ImVec2 pos = draw_data->DisplayPos;
				ImVec4 clip_rect = pcmd->ClipRect - ImVec4(pos.x, pos.y, pos.x, pos.y);

				// do a simple screen bounds test
				if (clip_rect.x < fb_width && clip_rect.y < fb_height && clip_rect.z >= 0.f && clip_rect.w >= 0.f) {
					Graphics::ViewportExtents vp(clip_rect.x, (fb_height - clip_rect.w), (clip_rect.z - clip_rect.x), (clip_rect.w - clip_rect.y));
					m_renderer->SetScissor(vp);

					m_material->SetTexture(s_textureName, reinterpret_cast<Graphics::Texture *>(pcmd->TextureId));
					m_material->SetPushConstant(s_vertexDepthName, pcmd->PrimDepth);
					m_renderer->DrawBufferDynamic(m_vtxBuffer.get(), vtxOffset, m_idxBuffer.get(), idxOffset, pcmd->ElemCount, m_material.get());
				}
			}
			idxOffset += pcmd->ElemCount;
		}
	}

	// so long as we haven't issued FlushCommandBuffers() yet, we're perfectly fine to do this upload out-of-order.
	m_vtxBuffer->BufferData(vtxStagingBuffer.size() * sizeof(ImDrawVert), vtxStagingBuffer.data());
	m_idxBuffer->BufferData(idxStagingBuffer.size() * sizeof(ImDrawIdx), idxStagingBuffer.data());

	m_renderer->FlushCommandBuffers();
}

void InstanceRenderer::CreateFontsTexture()
{
	ImGuiIO &io = ImGui::GetIO();
	unsigned char *pixels;
	int width, height;
	io.Fonts->GetTexDataAsRGBA32(&pixels, &width, &height);

	vector3f dataSize = { (float)width, (float)height, 0 };
	if (!m_fontsTexture || !(dataSize == m_fontsTexture->GetDescriptor().dataSize)) {
		Graphics::TextureDescriptor desc(
			Graphics::TEXTURE_RGBA_8888,
			dataSize,
			Graphics::LINEAR_REPEAT,
			false, false, false, 0,
			Graphics::TEXTURE_2D);

		m_fontsTexture.reset(m_renderer->CreateTexture(desc));
	}

	m_fontsTexture->Update(pixels, dataSize, Graphics::TEXTURE_RGBA_8888);
	io.Fonts->TexID = ImTextureID(m_fontsTexture.get());
}

void InstanceRenderer::DestroyFontsTexture()
{
	m_fontsTexture.reset();
	ImGui::GetIO().Fonts->TexID = 0;
}
