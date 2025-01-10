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

#include "../galaxy/SystemPath.h"
#include "SyonDraw.h"


void Syon::Initialize() {
	if (!Syon::m_path) {
		// Get the hyperspace source from Pi::game
		if (Pi::game) {
			fmt::print("Syon::m_path init to Pi::game->GetHyperspaceSource();\n");
			const SystemPath& hyperspaceSource = Pi::game->GetHyperspaceSource();
			Syon::m_path = new SystemPath(hyperspaceSource);
		} else {
			fmt::print("Pi::game is not initialized!\n");
		}
	}
}

void Syon::Shutdown() {
	// Clean up m_path
	delete Syon::m_path;
	Syon::m_path = nullptr;
}


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


		//m//_path = Pi.game.
	}

	// Range slider
	static float range[2] = {0.0f, 100.0f};
	ImGui::SliderFloat2("Range Slider", range, 0.0f, 100.0f);

	ImGui::End();
}




// This function has been taken from the editor ui
void Syon::DrawInternalSectorTool()
{


	if (Syon::Draw::LayoutHorizontal("Sector", 3, ImGui::GetFontSize())) {
		bool changed = false;
		changed |= ImGui::InputInt("X", &Syon::m_path->sectorX, 1, 0);
		changed |= ImGui::InputInt("Y", &Syon::m_path->sectorY, 1, 0);
		changed |= ImGui::InputInt("Z", &Syon::m_path->sectorZ, 1, 0);

		if (changed)
			Syon::m_path->systemIndex = 0;

		Syon::Draw::EndLayout();
	}

	ImGui::Separator();

	RefCountedPtr<const Sector> sec = Pi::game->GetGalaxy()->GetSector(Syon::m_path->SectorOnly());
	ImGui::BeginGroup();
	if (ImGui::BeginChild("Systems", ImVec2(ImGui::GetContentRegionAvail().x * 0.33, -ImGui::GetFrameHeightWithSpacing()))) {

		for (const Sector::System &system : sec->m_systems) {

			const vector3f& position = system.GetPosition();

			// Display in ImGui
			//ImGui::Text("Position: (%.2f, %.2f, %.2f)", position.x, position.y, position.z);

			// Convert to string for logging
			std::string positionStr = fmt::format("({:.2f}, {:.2f}, {:.2f})", position.x, position.y, position.z);
			//fmt::print("Position logged: {}\n", positionStr);

			std::string label = fmt::format("{} {} \uF023{}", system.GetName(), positionStr ,system.GetNumStars());

			if (ImGui::Selectable(label.c_str(), system.idx == Syon::m_path->systemIndex))
				Syon::m_path->systemIndex = system.idx;

			if (ImGui::IsItemClicked() && ImGui::IsMouseDoubleClicked(0)) {
				//Pi::game->LoadSystem(system.GetPath());
				ImGui::CloseCurrentPopup();
			}

		}

	}
	ImGui::EndChild();

	if (ImGui::Button("New System")) {
		// Ensure we generate a valid system index
		SystemPath newPath = Syon::m_path->SectorOnly();
		newPath.systemIndex = sec->m_systems.size();

		//Pi::game->NewSystem(newPath);
		ImGui::CloseCurrentPopup();
	}

	ImGui::SetItemTooltip("Create a new empty system in this sector.");

	ImGui::SameLine();

	if (ImGui::Button("Edit Selected")) {
		//Pi::game->LoadSystem(Syon::m_path->SystemOnly());
		ImGui::CloseCurrentPopup();
	}

	ImGui::SetItemTooltip("Load the selected system as a template.");

	ImGui::EndGroup();

	ImGui::SameLine();
	ImGui::BeginGroup();

	if (Syon::m_path->systemIndex < sec->m_systems.size()) {
		const Sector::System &system = sec->m_systems[Syon::m_path->systemIndex];

		//ImGui::PushFont(m_app->GetPiGui()->GetFont("pionillium", 16));

		ImGui::AlignTextToFramePadding();
		ImGui::TextUnformatted(system.GetName().c_str());

		//ImGui::PopFont();

		ImGui::Spacing();

		ImGui::TextUnformatted("Is Custom:");
		ImGui::SameLine(ImGui::CalcItemWidth());
		ImGui::TextUnformatted(system.GetCustomSystem() ? "yes" : "no");

		ImGui::TextUnformatted("Is Explored:");
		ImGui::SameLine(ImGui::CalcItemWidth());
		ImGui::TextUnformatted(system.GetExplored() == StarSystem::eEXPLORED_AT_START ? "yes" : "no");

		ImGui::TextUnformatted("Faction:");
		ImGui::SameLine(ImGui::CalcItemWidth());
		ImGui::TextUnformatted(system.GetFaction() ? system.GetFaction()->name.c_str() : "<none>");

		ImGui::TextUnformatted("Other Names:");
		ImGui::SameLine(ImGui::CalcItemWidth());

		ImGui::BeginGroup();
		for (auto &name : system.GetOtherNames())
			ImGui::TextUnformatted(name.c_str());
		ImGui::EndGroup();
	}
	ImGui::EndGroup();
}


void Syon::SayHelloWorld() {
	//char* str, char str2[] , char** strRef,  char* &strRef2

	//Syon::m_path = SystemPath:Parse("4,1,1")

	ImGui::Begin("Syon Tool");
	// m_stats.shield_mass_left
	// m_stats.hull_mass_left
	ImGui::Text("Hello World");

	Syon::Initialize();

	Syon::DrawInternalSectorTool();
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




	const SystemPath& path22 = SystemPath::Parse("(4,1,1)");

	RefCountedPtr<Sector> sec = Pi::game->GetGalaxy()->GetMutableSector(path22);



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
