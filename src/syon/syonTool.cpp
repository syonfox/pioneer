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

#include "enum_table.h" 			// For maping types to names for display.
#include "EditorIcons.h"

// for mod memory
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

// clen up  idk
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

			if (ImGui::Selectable(label.c_str(), system.idx == Syon::m_path->systemIndex)) {
				Syon::m_path->systemIndex = system.idx; // herfe we are updating the sector system idx for out path.
			}
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
	// This is the main sector system dump code.
	// Note how above

	ImGui::BeginGroup();

	if (Syon::m_path->systemIndex < sec->m_systems.size()) {
		const Sector::System &system = sec->m_systems[Syon::m_path->systemIndex];	// SectorSystem is some info exposed for sector agragations.

		const vector3f& position = system.GetPosition();	// this is the system position within a sector

		const SystemPath &systemPath = system.GetPath(); 	// A system path represence the index of a body in the galexy.

		// Dive into the star systems
		RefCountedPtr<Galaxy> galaxy = Pi::game->GetGalaxy();	// From the galacy we can lookup a system by the system path.
		RefCountedPtr<StarSystem> starSystem = galaxy->GetStarSystem(systemPath);



		//RefCountedPtr<StarSystem> pop = galaxy->GetStarSystem(systemPath);

		ImGui::AlignTextToFramePadding();

		ImGui::TextUnformatted(system.GetName().c_str());


		// Display in ImGui
		ImGui::Text("Position Sector f: (%f, %f, %f)", position.x/8, position.y/8, position.z/8);
		ImGui::Text("Position ly (X, Y, Z): (%.2f, %.2f, %.2f)", position.x, position.y, position.z);

		ImGui::Spacing();

		/*if (ImGui::BeginTable("SystemInfo", 2, ImGuiTableFlags_Borders | ImGuiTableFlags_Resizable)) {
			ImGui::TableNextColumn();
			ImGui::TextUnformatted("Is Custom:");
			ImGui::TableNextColumn();
			ImGui::TextUnformatted(system.GetCustomSystem() ? "yes" : "no");

			ImGui::TableNextColumn();
			ImGui::TextUnformatted("Is Explored:");
			ImGui::TableNextColumn();
			ImGui::TextUnformatted(system.GetExplored() == StarSystem::eEXPLORED_AT_START ? "yes" : "no");

			ImGui::TableNextColumn();
			ImGui::TextUnformatted("Faction:");
			ImGui::TableNextColumn();
			ImGui::TextUnformatted(system.GetFaction() ? system.GetFaction()->name.c_str() : "<none>");
			ImGui::EndTable();


		}*/

			ImGui::Spacing();


		// Start the table
		if (ImGui::BeginTable("SectorSystemDetails", 2, ImGuiTableFlags_Borders | ImGuiTableFlags_Resizable)) {
		    // System Name
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Name:");
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted(system.GetName().c_str());

			//Star Paths
			ImGui::TableNextColumn();
			ImGui::TextUnformatted("System Path:");
			ImGui::TableNextColumn();
			ImGui::Text("(%d, %d, %d, %d)", system.sx, system.sy, system.sz, system.idx);


		    // Position
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Position (Sector):");
		    ImGui::TableNextColumn();
		    ImGui::Text("(%d, %d, %d)", system.sx, system.sy, system.sz);

		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Position (Local):");
		    ImGui::TableNextColumn();
		    const vector3f &position = system.GetPosition();
		    ImGui::Text("(%.2f, %.2f, %.2f)", position.x, position.y, position.z);

		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Position (Full):");
		    ImGui::TableNextColumn();
		    vector3f fullPosition = system.GetFullPosition();
		    ImGui::Text("(%.2f, %.2f, %.2f)", fullPosition.x, fullPosition.y, fullPosition.z);

		    // Number of Stars
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Number of Stars:");
		    ImGui::TableNextColumn();
		    ImGui::Text("%u", system.GetNumStars());

		    //Star Types
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Star Types:");
		    ImGui::TableNextColumn();
		    for (unsigned i = 0; i < system.GetNumStars(); ++i) {
		    	const SystemBody::BodyType &bodyType = system.GetStarType(i);
		        ImGui::TextUnformatted(ENUM_BodyType[bodyType].name);
		    }

		    // Seed
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Seed:");
		    ImGui::TableNextColumn();
		    ImGui::Text("%u", system.GetSeed());


		    // Faction
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Faction:");
		    ImGui::TableNextColumn();
		    const Faction *faction = system.GetFaction();
		    ImGui::TextUnformatted(faction ? faction->name.c_str() : "<None>");

	    	// Pop
			fixed totalPop = starSystem->GetTotalPop();
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Population:");
		    ImGui::TableNextColumn();
		    ImGui::Text("%.3f billion", totalPop.ToFloat());
		    // Exploration Status
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Exploration Status:");
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted(system.IsExplored() ? "Explored" : "Unexplored");

		    // Exploration Time
		    if (system.IsExplored()) {
		        ImGui::TableNextColumn();
		        ImGui::TextUnformatted("Exploration Time:");
		        ImGui::TableNextColumn();
		        ImGui::Text("%.2f", system.GetExploredTime());
		    }

		    // Other Names
		    ImGui::TableNextColumn();
		    ImGui::TextUnformatted("Other Names:");
		    ImGui::TableNextColumn();
		    ImGui::BeginGroup();
		    for (const auto &name : system.GetOtherNames()) {
		        ImGui::TextUnformatted(name.c_str());
		    }


   			ImGui::EndGroup();

		    ImGui::EndTable();


			if (starSystem) {
				// Get descriptions
				const std::string &shortDesc = starSystem->GetShortDescription();
				const std::string &longDesc = starSystem->GetLongDescription();

				// Display in ImGui
				ImGui::TextUnformatted("Short Description:");
				ImGui::Spacing();
				ImGui::TextWrapped("%s", shortDesc.c_str());

				ImGui::Spacing();
				ImGui::TextUnformatted("Long Description:");
				ImGui::Spacing();
				ImGui::TextWrapped("%s", longDesc.c_str());
			} else {
				ImGui::TextUnformatted("Error: Could not load StarSystem.");
			}
			//const StarSystem star_system = Galaxy.GetStarSystem(systemPath);
			//for (unsigned i = 0; i < system.GetNumStars(); ++i) {
			//ImGui::TextUnformatted(ENUM_BodyType[bodyType].name);
			//}


		}



		//SystemPath GetPath() const { return SystemPath(sx, sy, sz, idx); }


		//for (std::vector<Sector::System>::iterator i = ps->m_systems.begin(); i != ps->m_systems.end(); ++i, ++sysIdx) {

		//}


	}
	ImGui::EndGroup();
}
/*
void ProcessSectorSystem(const Sector::System &system)
{
	RefCountedPtr<Galaxy> galaxy = Pi::game->GetGalaxy();
	RefCountedPtr<StarSystem> starsystem = galaxy->GetStarSystem(system.GetPath());
	for (const auto &b : starsystem->GetBodies()) {
		auto children = b->GetChildren();
		if (std::find_if(children.cbegin(), children.cend(), [](const SystemBody *kid) {
				return kid->GetType() == SystemBody::TYPE_STARPORT_SURFACE;
			}) != children.cend())
			// the radius and the mass of the planet is returned in the radii and the mass of the earth
				// therefore the result is obtained in g
					//Planets.emplace_back(b->GetName(), system.GetName(), b->GetMassAsFixed().ToDouble() / b->GetRadiusAsFixed().ToDouble() / b->GetRadiusAsFixed().ToDouble(), b->GetPath());
	}
}

*/
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
