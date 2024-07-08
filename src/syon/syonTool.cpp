//
// Created by mango on 25/05/24.
//


#include "syonTool.h"

void ShowSyonToolWindow(bool* p_open) {
	// Create a window called "Syon Tool"
	ImGui::Begin("Syon Tool", p_open);

	// Add some buttons
	if (ImGui::Button("Button 1")) {
		// Action for Button 1
		ImGui::Text("Button 1 Pressed");
	}
	if (ImGui::Button("Button 2")) {
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



void SayHelloWorld() {
	//char* str, char str2[] , char** strRef,  char* &strRef2

	ImGui::Begin("Syon Tool");


	ImGui::Text("Hello World");


	ImGui::End();
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
