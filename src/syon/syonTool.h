//
// Created by mango on 25/05/24.
//

#ifndef PIONEER_SYONTOOL_H
#define PIONEER_SYONTOOL_H

// Include the ImGui header
//#include "imgui.h"
#include "../pigui/PiGui.h"
// Function to show the Syon Tool window
#include "galaxy/SystemPath.h"


// Class
// // ok we need to keep track of our foxi state and make changes declaration
// class Syon {
// public:
// 	// Constructor
// 	Syon();
//
// 	// Destructor
// 	~Syon();
//
// 	// Member functions
// 	void SayHelloWorld();
// 	void TestStateIntrospection();
// };


namespace Syon {

	// Forward declaration of game-related structures
	struct GameData;

	// Function declaration to show the Syon Tool window
	// right now this is linked to each draw fraim by the PerfInfo
	void ShowSyonToolWindow(bool* p_open);

	// Static manager functions
	void Initialize();
	void Shutdown();
	void SayHelloWorld();
	void TestStateIntrospection();
	void DrawInternalSectorTool();
	void DrawWorldViewStats();
	// Game-related pointers
	extern GameData* g_GameData;


   // SystemPath* m_path = nullptr;



  // Static SystemPath pointer in the namespace
    inline SystemPath* m_path = nullptr;

} // namespace Syon





// void ShowSyonToolWindow(bool* p_open);
//
// void SayHelloWorld();
//
// void Syon::TestStateIntrospection();

#endif //PIONEER_SYONTOOL_H
