//
// Created by mango on 25/05/24.
//


#include "syonTool.h"
#include "Frame.h"

#include "Game.h"
#include "Space.h"
#include "SectorView.h"

#include "Pi.h"
#include "Player.h"



void Syon::ShowSyonToolWindow(bool* p_open) {
	// Create a window called "Syon Tool"
	ImGui::Begin("Syon Foxi Co Tool", p_open);

	// Add some buttons
	if (ImGui::Button("FOXI CO BLUF")) {
		// Action for Button 1
		ImGui::Text("We have been asked to facilatate trade between the solar federation and Commonwealth.  We have also been asked to reduces their strength when provoked.");

	}
	if (ImGui::Button("Find Target")) {
		// Action for Button 2
		ImGui::Text("Button 2 Pressed");
	}

	// Display Hello, World! texts
	ImGui::Text("Hello, World 1!");
	ImGui::Text("Hello, World 2!");

	// Create a table with 3 columns
	if (ImGui::BeginTable("Table", 3)) {
		// Table Headers
		ImGui::TableSetupColumn("Column 1");
		ImGui::TableSetupColumn("Column 2");
		ImGui::TableSetupColumn("Column 3");
		ImGui::TableHeadersRow();

		// Table Rows
		for (int row = 0; row < 3; row++) {
			ImGui::TableNextRow();
			for (int column = 0; column < 3; column++) {
				ImGui::TableSetColumnIndex(column);
				ImGui::Text("Row %d, Col %d", row, column);
			}
		}
		ImGui::EndTable();
	}

	// Range slider
	static float range[2] = {0.0f, 100.0f};
	ImGui::SliderFloat2("Range Slider", range, 0.0f, 100.0f);

	ImGui::End();
}



void Syon::SayHelloWorld() {
	//char* str, char str2[] , char** strRef,  char* &strRef2

	ImGui::Begin("Syon Tool");
	// m_stats.shield_mass_left
	// m_stats.hull_mass_left
	ImGui::Text("Hello World");

	// Syon::DrawWorldViewStats();

	ImGui::End();
}


void Syon::DrawWorldViewStats()
{
	vector3d pos = Pi::player->GetPosition();
	vector3d abs_pos = Pi::player->GetPositionRelTo(Pi::game->GetSpace()->GetRootFrame());

	const FrameId playerFrame = Pi::player->GetFrame();

	ImGui::TextUnformatted(fmt::format("Player Position: {:.5}, {:.5}, {:.5}", pos.x, pos.y, pos.z).c_str());
	ImGui::TextUnformatted(fmt::format("Absolute Position: {:.5}, {:.5}, {:.5}", abs_pos.x, abs_pos.y, abs_pos.z).c_str());

	const Frame *frame = Frame::GetFrame(playerFrame);
	const SystemPath &path(frame->GetSystemBody()->GetPath());

	std::string tempStr;
	tempStr = fmt::format("Relative to frame: {} [{}, {}, {}, {}, {}]",
		frame->GetLabel(), path.sectorX, path.sectorY, path.sectorZ, path.systemIndex, path.bodyIndex);

	ImGui::TextUnformatted(tempStr.c_str());

	tempStr = fmt::format("Distance from frame: {:.2f} km, rotating: {}, has rotation: {}",
		pos.Length() / 1000.0, frame->IsRotFrame(), frame->HasRotFrame());

	ImGui::TextUnformatted(tempStr.c_str());

	ImGui::Spacing();

	//Calculate lat/lon for ship position
	const vector3d dir = pos.NormalizedSafe();
	const float lat = RAD2DEG(asin(dir.y));
	const float lon = RAD2DEG(atan2(dir.x, dir.z));

	ImGui::TextUnformatted(fmt::format("Lat / Lon: {:.8} / {:.8}", lat, lon).c_str());

	char aibuf[256];
	Pi::player->AIGetStatusText(aibuf);

	ImGui::TextUnformatted(aibuf);

	ImGui::Spacing();
	ImGui::TextUnformatted("Player Model ShowFlags:");

	// using Flags = SceneGraph::Model::DebugFlags;

	// bool showColl = m_state->playerModelDebugFlags & Flags::DEBUG_COLLMESH;
	// bool showBBox = m_state->playerModelDebugFlags & Flags::DEBUG_BBOX;
	// bool showTags = m_state->playerModelDebugFlags & Flags::DEBUG_TAGS;
	//
	// bool changed = ImGui::Checkbox("Show Collision Mesh", &showColl);
	// changed |= ImGui::Checkbox("Show Bounding Box", &showBBox);
	// changed |= ImGui::Checkbox("Show Tag Locations", &showTags);

	/* clang-format off */
	// if (changed) {
	// 	m_state->playerModelDebugFlags = (showColl ? Flags::DEBUG_COLLMESH : 0)
	// 		| (showBBox ? Flags::DEBUG_BBOX : 0)
	// 		| (showTags ? Flags::DEBUG_TAGS : 0);
	// 	Pi::player->GetModel()->SetDebugFlags(m_state->playerModelDebugFlags);
	// }
	/* clang-format on */

	if (Pi::player->GetNavTarget() && Pi::player->GetNavTarget()->GetSystemBody()) {
		const auto *sbody = Pi::player->GetNavTarget()->GetSystemBody();
		ImGui::TextUnformatted(fmt::format("Name: {}, Population: {}", sbody->GetName(), sbody->GetPopulation() * 1e9).c_str());
	}

	if (Pi::GetView() == Pi::game->GetSectorView()) {
		if (ImGui::Button("Dump Selected System")) {
			SystemPath path = Pi::game->GetSectorView()->GetSelected();
			RefCountedPtr<StarSystem> system = Pi::game->GetGalaxy()->GetStarSystem(path);

			if (system)
				system->Dump(Log::GetLog()->GetLogFileHandle());
		}
	}

}

/*
// Main application code
int main(int, char**) {
	// Initialize your platform and renderer bindings here

	// Setup Dear ImGui context
	IMGUI_CHECKVERSION();
	ImGui::CreateContext();
	ImGuiIO& io = ImGui::GetIO(); (void)io;

	// Setup Dear ImGui style
	ImGui::StyleColorsDark();

	// Setup Platform/Renderer bindings
	// ImGui_ImplXXXX_Init();

	bool show_demo_window = true;

	// Main loop
	while (true) {
		// Poll and handle events (inputs, window resize, etc.)
		// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if Dear ImGui wants to use your inputs.
		// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
		// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.

		// Start the ImGui frame
		ImGui_ImplXXXX_NewFrame();
		ImGui::NewFrame();

		// Show Syon Tool window
		if (show_demo_window) {
			ShowSyonToolWindow(&show_demo_window);
		}

		// Rendering
		ImGui::Render();
		ImGui_ImplXXXX_RenderDrawData(ImGui::GetDrawData());

		// Your platform-specific rendering code here...
	}

	// Cleanup
	ImGui_ImplXXXX_Shutdown();
	ImGui::DestroyContext();

	return 0;
}
*/
