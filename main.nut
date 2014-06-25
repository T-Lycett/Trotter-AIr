import("util.MinchinWeb", "MetaLib", 4);
import("util.superlib", "SuperLib", 19);
require("AirportManager.nut");
require("StationStats.nut");
require("TownManager");
Tile <- SuperLib.Tile //temp fix for bug in SuperLib
COMPANYID <- 0;

class Trotter_AIr extends AIController 
{
	
	airportManager = null;
	stationStats = null;
	homeTown = null;
	spiralWalker = null;
	helper = null;
	airportLib = null;
	PAXID = 0;
	
	constructor() {
	
	this.spiralWalker = _MinchinWeb_SW_();
	this.stationStats = StationStats();
	this.airportManager = AirportManager();

	helper = _SuperLib_Helper();
	airportLib = _SuperLib_Airport();
	

	}
}



function Trotter_AIr::Start() {
	
	AILog.Info("Started");
	
	this.SetBasicInfo();
	AICompany.SetLoanAmount(300000);
	
	airportManager.PlanNewAirportsAndAircraft(false);
	airportManager.BuildNewAirportsAndAircraft();
	
	while (true) {
  		airportManager.MaintainAirports();
		//if (airportManager.PlanNewAirportsAndAircraft(false)) airportManager.BuildNewAirportsAndAircraft();
		this.Sleep(10)
  	}
}



function SetBasicInfo() {
	local iii = 0;
	local name = "Trotter AIr #";

	//set name
	do {
		iii++;
	}
	while (!AICompany.SetName(name + iii))
	
	COMPANYID = AICompany.ResolveCompanyID(AICompany.COMPANY_SELF);
	
	//choose home town and build hq there.
	homeTown = AITownList();
	homeTown.Valuate(AITown.GetPopulation);
	homeTown = homeTown.Begin();
	AILog.Info("Home Town: " + AITown.GetName(homeTown));
	this.BuildHQ(homeTown);
	
	AICompany.SetAutoRenewStatus(false);		
	
	PAXID = helper.GetPAXCargo();
	
}

//Builds HQ as close to centre of town as possible.
function BuildHQ(HQTown) {
	local iii = 0;
	local currentTile = null;
	
	spiralWalker.Start(AITown.GetLocation(HQTown));
	
	do {
		spiralWalker.Walk();
		currentTile = spiralWalker.GetTile();
	
		if (AITile.IsBuildableRectangle(currentTile, 2, 2)) {
	
			if (AICompany.BuildCompanyHQ(currentTile)) {
				spiralWalker.Reset();
				return true;
			} else {
				if (AITile.LevelTiles(currentTile, AIMap.GetTileIndex(AIMap.GetTileX(currentTile) + 1, AIMap.GetTileY(currentTile) + 1)) && AICompany.BuildCompanyHQ(currentTile)) {
					spiralWalker.Reset();
					return true;
				} 
			}
		}
		iii++;
	} while (iii < 10000)
	return false
}