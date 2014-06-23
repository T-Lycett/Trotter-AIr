class AirportManager {
	loadPerMilUpperBoundry = 980;
	loadPerMilLowerBoundry = 300;
	maxFlightDistance = 0;
	minFlightDistance = 0;
	minPopulationForAirport = 0;
	airportLib = null;
	helper = null;
	spiralWalker = null;
	stationStats = null;
	PAXID = 0;
	townToConnect = null;
	aircraftToUse = 0;
	airportToUse = 0;
	numberOfAircraftToUse = 0;
	aircraftBuilt = null;
	aircraftAirportBuiltAt = null;
	fullCapacityCountLimit = null;
	fullCapacityCountAllowedToUpgrade = null;
	constructor() {
		loadPerMilUpperBoundry = 980;
		loadPerMilLowerBoundry = 300;
		maxFlightDistance = 200; //aprox maximum distance a flight should take, in tiles.
		minFlightDistance = 50; //aprox minimum distance a flight should take, in tiles.
		minPopulationForAirport = 1000;
		airportLib = _SuperLib_Airport();
		spiralWalker = _MinchinWeb_SW_();
		helper = _SuperLib_Helper();
		stationStats = StationStats();
		PAXID = helper.GetPAXCargo();
		townToConnect = AIList();
		aircraftBuilt = AIList();
		aircraftAirportBuiltAt = AIList();
		fullCapacityCountLimit = 5;
		fullCapacityCountAllowedToUpgrade = 2;
	}
}

function AirportManager::PlanNewAirportsAndAircraft(maintainingExistingAirport, airport = null) {
	
	
		local townList = AITownList();
		local townsWithoutAirports = AIList();
		townsWithoutAirports.AddList(stationStats.GetTownsWithoutAirports());
		
		townToConnect.Clear();
		
		airportToUse = this.GetAirportToUse();
		aircraftToUse = this.GetBestAircraft();
		
		townList.Valuate(AITown.GetPopulation);
		townList.RemoveBelowValue(minPopulationForAirport);
		townList.KeepList(townsWithoutAirports);
		AILog.Info("Planning new airports");
	if	(!maintainingExistingAirport) {
		
		if (townList.Count() >= 2) {
			townList.Valuate(AITown.GetPopulation);
			townToConnect.AddItem(townList.Begin(), 1);
		
			townList.RemoveItem(townToConnect.Begin());
			
			foreach (town, score in townList) {
				score = this.ScoreTown(town, false, townToConnect.Begin());
				if (score == 0) townList.RemoveItem(town);
				//AILog.Info(AITown.GetName(town) + " " + score);
			}
			townToConnect.AddItem(townList.Begin(), 0);
			
			AILog.Info("Planned to connect " + AITown.GetName(townToConnect.Begin()) + " to " + AITown.GetName(townToConnect.Next()));
			numberOfAircraftToUse = this.GetNumberOfAircraftToUse();
			AILog.Info("Planned to use " + numberOfAircraftToUse + " " + AIEngine.GetName(aircraftToUse) + " aircraft.");
		} else {
			AILog.Info("Not enough towns suitable for airports.");
			return false
		}
	} else {
		if (!townList.IsEmpty()) {
			local firstTown = stationStats.GetTownOfAirport(airport);
			foreach (town, score in townList) {
				score = this.ScoreTown(town, false, firstTown);
				if (score == 0) townList.RemoveItem(town);
				//AILog.Info(AITown.GetName(town) + " " + score);
			}
			townList.Sort(AIList.SORT_BY_VALUE, false);
			townToConnect.AddItem(townList.Begin(), 0);
			numberOfAircraftToUse = 1;
			AILog.Info("Planned to connect " + AIBaseStation.GetName(airport) + " to " + AITown.GetName(townToConnect.Begin()));
		} else {
			AILog.Info("No town is suitable to connect to this airport.");
			return false
		}
	}

	return true
}



function AirportManager::GetAirportsToUpgradeService() {
	local airportsOwned = AIStationList(AIStation.STATION_AIRPORT);
	local airportsToUpgradeService = AIList();
	
	foreach (airport, _ in airportsOwned) {
		local fullCapacityCount = stationStats.GetAirportFullCapacityCount(airport);
		local totalCapacity = stationStats.GetTotalAircraftCapacity(airport, PAXID);
		local aircraftWithAirportAsOrder = AIVehicleList_Station(airport);
		local numberOfAircraft = aircraftWithAirportAsOrder.Count();
		
		AILog.Info("Full capacity count is " + fullCapacityCount + " at " + AIBaseStation.GetName(airport));
		
		if (fullCapacityCount >= fullCapacityCountLimit || numberOfAircraft == 0 || totalCapacity < AIStation.GetCargoWaiting(airport, PAXID)) {
			airportsToUpgradeService.AddItem(airport, 0);
			//if (fullCapacityCount >= fullCapacityCountLimit) {
				//AILog.Info("1");
			//}
			//if (numberOfAircraft == 0) {
				//AILog.Info("2");
			//}
			//if (totalCapacity < AIStation.GetCargoWaiting(airport, PAXID)) {
				//AILog.Info("3" + " total capacity = " + totalCapacity + " " + AIStation.GetCargoWaiting(airport, PAXID));
			//}
		}
	}
	return airportsToUpgradeService;
}



function AirportManager::MaintainAirports() {
	
	stationStats.UpdateAirportStats();
	
	local aircraftCount = AIVehicleList()
	foreach (vehicle, _ in aircraftCount) {
		if (AIVehicle.GetVehicleType(vehicle) != AIVehicle.VT_AIR) aircraftCount.RemoveItem(vehicle);
	}
	aircraftCount = aircraftCount.Count()
	if (aircraftCount == 0) aircraftCount = 1;
	
		local airportsToUpgradeService = AIList();
		airportsToUpgradeService.AddList(this.GetAirportsToUpgradeService());
		aircraftToUse = this.GetBestAircraft();
		AILog.Info("Maintaining Airports");
		foreach (airport, _ in airportsToUpgradeService) {
						
			AILog.Info("Maintaining " + AIBaseStation.GetName(airport));
			
			local airportsConnected = AIList();
			local success = false;
			
			airportsConnected = stationStats.GetAllAirportsConnectedToAirport(airport);
			
			local numberOfAircraft = AIVehicleList_Station(airport);
			numberOfAircraft = numberOfAircraft.Count();
			if (numberOfAircraft == 0) {
				AILog.Info("No Aircraft going to or from" + AIBaseStation.GetName(airport));
			} else {
				AILog.Info("Too many passangers for current aircraft at " + AIBaseStation.GetName(airport));
			}
			//AILog.Info("Average load per mil (per 1000) is " + averageLoadPerMil);
							
			//Try to add aircraft to existing route.
			
			foreach (airportConnected, _ in airportsConnected) {
				airportsConnected.SetValue(airportConnected, AIMap.DistanceManhattan(airportLib.GetAirportTile(airportConnected), airportLib.GetAirportTile(airport)));
			}
			airportsConnected.KeepAboveValue(minFlightDistance.tointeger());
			airportsConnected.KeepBelowValue(maxFlightDistance.tointeger());
			
			foreach (airportConnected, _ in airportsConnected) {
				local totalCapacity = stationStats.GetTotalAircraftCapacity(airportConnected, PAXID);
				if (totalCapacity > AIStation.GetCargoWaiting(airportConnected, PAXID) && fullCapacityCountAllowedToUpgrade > stationStats.GetAirportFullCapacityCount(airportConnected)) {
					airportsConnected.SetValue(airportConnected, 0);
				} else {
					if (stationStats.GetAirportFullCapacityCount(airportConnected) > 0) {
						airportsConnected.SetValue(airportConnected, stationStats.GetAirportFullCapacityCount(airportConnected));
					} else {
						airportsConnected.SetValue(airportConnected, 1);
					}
				}
			}
				
			airportsConnected.RemoveValue(0);
			
					
			if (!airportsConnected.IsEmpty()) {
				airportsConnected.Sort(AIList.SORT_BY_VALUE, true);
				aircraftToUse = this.GetBestAircraft();
				this.BuildAndOrderAircraft(1, airport, airportsConnected.Begin());
				airportsToUpgradeService.RemoveItem(airport);
				airportsToUpgradeService.RemoveItem(airportsConnected.Begin());
				stationStats.ResetAirportStats(airport);
				stationStats.ResetAirportStats(airportsConnected.Begin());
				success = true
			}
				
			if(!success) {
				//Try to establish a route to an airport with no aircraft.
				local airportsOwned = AIStationList(AIStation.STATION_AIRPORT);
				airportsOwned.RemoveItem(airport);
				
				foreach (airportOwned, _ in airportsOwned) {
					airportsOwned.SetValue(airportOwned, AIMap.DistanceManhattan(airportLib.GetAirportTile(airportOwned), airportLib.GetAirportTile(airport)));
				}
				airportsOwned.KeepAboveValue(minFlightDistance.tointeger());
				airportsOwned.KeepBelowValue(maxFlightDistance.tointeger());
				
				foreach (airportOwned, _ in airportsOwned) {
					local airportAircraftList = AIVehicleList_Station(airportOwned);
					airportsOwned.SetValue(airportOwned, airportAircraftList.Count());
				}
				airportsOwned.KeepValue(0);
					

				if (!airportsOwned.IsEmpty()) {
					aircraftToUse = this.GetBestAircraft();
					this.BuildAndOrderAircraft(1, airport, airportsOwned.Begin());
					airportsToUpgradeService.RemoveItem(airport);
					airportsToUpgradeService.RemoveItem(airportsOwned.Begin());
					stationStats.ResetAirportStats(airport);
					stationStats.ResetAirportStats(airportsOwned.Begin());
					success = true;
				}
			}
			if(!success) {
				//Try to establish a route with another airport.
				local airportsOwned = AIStationList(AIStation.STATION_AIRPORT);
					
				airportsOwned.RemoveItem(airport);
					
				aircraftToUse = this.GetBestAircraft();
				
				foreach (airportOwned, _ in airportsOwned) {
					airportsOwned.SetValue(airportOwned, AIMap.DistanceManhattan(airportLib.GetAirportTile(airportOwned), airportLib.GetAirportTile(airport)));
				}
				airportsOwned.KeepAboveValue(minFlightDistance.tointeger());
				airportsOwned.KeepBelowValue(maxFlightDistance.tointeger());
				
				foreach (tempAirport, _ in airportsOwned) {
					local totalCapacity = stationStats.GetTotalAircraftCapacity(tempAirport, PAXID);
					if (totalCapacity > AIStation.GetCargoWaiting(tempAirport, PAXID) && fullCapacityCountAllowedToUpgrade > stationStats.GetAirportFullCapacityCount(tempAirport)) {
						airportsOwned.SetValue(tempAirport, 0);
					} else {
						if (stationStats.GetAirportFullCapacityCount(tempAirport) > 0) {
							airportsOwned.SetValue(tempAirport, stationStats.GetAirportFullCapacityCount(tempAirport));
						} else {
							airportsOwned.SetValue(tempAirport, 1);
						}
					}
					
				}
					
				airportsOwned.RemoveValue(0);
					
				if (!airportsOwned.IsEmpty()) {
					airportsOwned.Sort(AIList.SORT_BY_VALUE, true);
					this.BuildAndOrderAircraft(1, airport, airportsOwned.Begin());
					airportsToUpgradeService.RemoveItem(airport);
					airportsToUpgradeService.RemoveItem(airportsOwned.Begin());
					stationStats.ResetAirportStats(airport);
					stationStats.ResetAirportStats(airportsOwned.Begin());
					success = true;
				}
			} 
			if (!success) {
				//Try to build an airport to establish route with.
				if (this.PlanNewAirportsAndAircraft(true, airport)) {
					if (this.BuildNewAirportsAndAircraft(airport)) {
						airportsToUpgradeService.RemoveItem(airport);
						stationStats.ResetAirportStats(airport);
						success = true;
					}
				}
			}
		}
}



function AirportManager::BuildNewAirportsAndAircraft(existingAirport = 0) {
	local airportIsBuilt = true;
	local vehiclesAreBuilt = true;
	local airportTile = null;
	local airportBuilt = AIList();
	
	foreach (town, _ in townToConnect) {
		AILog.Info("Building airport at " + AITown.GetName(town));
		
		if (AITown.GetRating(town, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_APPALLING || 
				AITown.GetRating(town, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_VERY_POOR) {
			local tile = null;
			
			AILog.Info("Planting trees at " + AITown.GetName(town) + " Rating: " + AITown.GetRating(town, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)));
			
			spiralWalker.Start(AITown.GetLocation(town));
			do {
				spiralWalker.Walk();
				tile = spiralWalker.GetTile();
				AITile.PlantTree(tile);
			} while (AITown.IsWithinTownInfluence(town, tile));
		}
		
		while (AITown.GetRating(town, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_APPALLING || 
				AITown.GetRating(town, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_VERY_POOR) {
			AILog.Info("Bribing " + AITown.GetName(town) + " Rating: " + AITown.GetRating(town, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)));
			AITown.PerformTownAction(town, 7);
		}

		airportTile = airportLib.BuildAirportInTown(town, airportToUse, PAXID, PAXID);
		if (airportTile != null) {
			local airportID = AIStation.GetStationID(airportTile);
			stationStats.InitializeAirport(airportID, town);
			airportBuilt.AddItem(airportID, AIDate.GetCurrentDate());
			AILog.Info("Built airport");
		} else { 
			airportIsBuilt = false;
		}
			//airportTile = BuildAirportAtTown(town);
			//if (airportTile != null) {
				//airportIsBuilt = true;
				//stationStats.InitializeAirport(AIStation.GetStationID(airportTile), town);
				//airportBuilt.AddItem(airport, AIDate.GetCurrentDate());
				//AILog.Info("Built airport");
			//}
		//}		
	}
	
	if (airportIsBuilt == true) {
		if (airportBuilt.Count() == 2) {
			if (!BuildAndOrderAircraft(numberOfAircraftToUse, airportBuilt.Begin(), airportBuilt.Next())) vehiclesAreBuilt = false;
		}
		if (airportBuilt.Count() == 1) {
			if (!BuildAndOrderAircraft(numberOfAircraftToUse, airportBuilt.Begin(), existingAirport)) vehiclesAreBuilt = false;
		}
	} else {
		foreach (airport, _ in airportBuilt) {
			AIAirport.RemoveAirport(airportLib.GetAirportTile(airport));
		}
	}
	return airportIsBuilt && vehiclesAreBuilt
}



function BuildAndOrderAircraft(numberOfAircraftToBuild, airportA, airportB) {
	local iii = 1;
	local aircraftBuilt = AIList();
	
	for ( ; iii <= numberOfAircraftToBuild; iii++) {
		local vehicleBuilt = 0; 
		if (iii % 2 == 0) {
			vehicleBuilt = AIVehicle.BuildVehicle(airportLib.GetHangarTile(airportA), aircraftToUse);
			//if (AIVehicle.IsValidVehicle(vehicleBuilt)) {
				aircraftBuilt.AddItem(vehicleBuilt, iii);
				stationStats.InitializeAircraft(vehicleBuilt, airportA);
			//} else {
				//return false;
			//}
		} else {
			vehicleBuilt = AIVehicle.BuildVehicle(airportLib.GetHangarTile(airportB), aircraftToUse);
			//if (AIVehicle.IsValidVehicle(vehicleBuilt)) {
				aircraftBuilt.AddItem(vehicleBuilt, AIDate.GetCurrentDate());
				stationStats.InitializeAircraft(vehicleBuilt, airportB);
			//} else {
				//return false;
			//}
		}
	}

	foreach (aircraft, _ in aircraftBuilt) {
		local nextAirport = 0;
		AIOrder.AppendOrder(aircraft, airportLib.GetAirportTile(stationStats.GetAircraftAirportBuiltAt(aircraft)), AIOrder.AIOF_NONE);
		if (stationStats.GetAircraftAirportBuiltAt(aircraft) == airportA) {
			nextAirport = airportB;
		} else { 
			nextAirport = airportA;
		}
		AIOrder.AppendOrder(aircraft, airportLib.GetAirportTile(nextAirport), AIOrder.AIOF_NONE);
		AIVehicle.StartStopVehicle(aircraft);
	}
	return true;
}


function AirportManager::AreTownsWithinFlightRange(townA, townB) {
	if (AITown.GetDistanceManhattanToTile(townA, AITown.GetLocation(townB)) < maxFlightDistance && AITown.GetDistanceManhattanToTile(townA, AITown.GetLocation(townB)) > minFlightDistance) {
		return true;
	} else {
		return false;
	}
}



//Valuator
//Scores a town to transport passangers to and from.
//A higher score is better.
//townScoring: town to give score to.
//maintainingExistingAirport: true if function has been called while maintaining an airport.
//firstTown: the town that cargo will be transfered to and from.
//Returns score as integer.
//TODO: implement score when maintaining an airport.
function AirportManager::ScoreTown(townScoring = 0, maintainingExistingAirport = false, firstTown = -1) {
	
	if (firstTown != -1) {
		if (!AirportManager.AreTownsWithinFlightRange(townScoring, firstTown)) return 0;
	}
	
	local townList = AITownList();
	local townList_2 = AITownList();
	if (maintainingExistingAirport) townList.RemoveItem(firstTown);
	local population = AITown.GetPopulation(townScoring)
	local populationScore = 0;
	local populationScoreWeight = 1;
	local townsInRange = 0;
	local townsInRangeScore = 0;
	local townsInRangeScoreWeight = 1;
	local score = 0;
	
	local maxPopulation = 1;
	local maxTownsInRange = 1;
	
	townList.Valuate(AITown.GetPopulation);
	townList_2.Valuate(AITown.GetPopulation);
	
	townList.KeepAboveValue(minPopulationForAirport);
	townList_2.KeepAboveValue(minPopulationForAirport);

	foreach (tempTown, _ in townList) {
		
		if (AITown.GetPopulation(tempTown) > maxPopulation) maxPopulation = AITown.GetPopulation(tempTown);
		
		local tempTownsInRange = 0;
		foreach (tempTown_2, _ in townList_2) {
			if (this.AreTownsWithinFlightRange(tempTown, tempTown_2)) tempTownsInRange++;
		}
		if (tempTownsInRange > maxTownsInRange) maxTownsInRange = tempTownsInRange;
		
		if (this.AreTownsWithinFlightRange(tempTown, townScoring)) townsInRange++;
	}
	populationScore = population * 100;
	populationScore = populationScore / maxPopulation;
	//AILog.Info("AirportManager.ScoreTown: " + AITown.GetName(townScoring) + " " + populationScore + " population:" + population + " max:" + maxPopulation);
	townsInRangeScore = townsInRange * 100;
	townsInRangeScore = townsInRangeScore / maxTownsInRange;
	score = ((populationScore * populationScoreWeight) + (townsInRangeScore * townsInRangeScoreWeight)) / 2;
	
	//AILog.Info("AirportManager.ScoreTown: " + AITown.GetName(townScoring) + " " + score + " " + populationScore + " " + townsInRangeScore);
	
	return score.tointeger()
}





function GetBestAircraft() {
	local aircraftList = AIEngineList(AIVehicle.VT_AIR);
	aircraftList.Valuate(AIEngine.IsBuildable);
	aircraftList.KeepValue(1);
	aircraftList.Valuate(AIEngine.GetCargoType);
	aircraftList.KeepValue(PAXID);
	foreach (aircraft, _ in aircraftList) {
		if (!airportLib.AreThereAirportsForPlaneType(AIEngine.GetPlaneType(aircraft))) aircraftList.RemoveItem(aircraft);
	}
	aircraftList.Valuate(this.ScoreAircraft, aircraftList);
		
	return aircraftList.Begin()
}




function ScoreAircraft(aircraft, aircraftList) {
	local capacity = AIEngine.GetCapacity(aircraft);
	local reliability = AIEngine.GetReliability(aircraft);
	local maxSpeed = AIEngine.GetMaxSpeed(aircraft);
	
	local maxCapacity = 0;
	local maxReliability = 0;
	local maxMaxSpeed = 0;
	
	local capacityPercentage = 0;
	local reliabilityPercentage = 0;
	local maxSpeedPercentage = 0;
	
	local capacityWeight = 1;
	local reliabilityWeight = 1;
	local maxSpeedWeight = 1;
	
	local score = 0;
	
	//would be better using aircraftList.Valuate(...)
	foreach (tempAircraft, _ in aircraftList) {
		local tempCapacity = AIEngine.GetCapacity(tempAircraft);
		local tempReliability = AIEngine.GetReliability(tempAircraft);
		local tempMaxSpeed = AIEngine.GetMaxSpeed(tempAircraft);
		
		if (tempCapacity > maxCapacity) maxCapacity = tempCapacity;
		if (tempReliability > maxReliability) maxReliability = tempReliability;
		if (tempMaxSpeed > maxMaxSpeed) maxMaxSpeed = tempMaxSpeed;
	}
	
	capacityPercentage = (capacity * 100) / maxCapacity;
	reliabilityPercentage = (reliability * 100) / maxReliability;
	maxSpeedPercentage = (maxSpeed * 100) / maxMaxSpeed;
	
	score = (((capacityPercentage * capacityWeight) + (reliabilityPercentage * reliabilityWeight) + (maxSpeedPercentage * maxSpeedWeight)) / 3);
	
	//AILog.Info(capacityPercentage + " " + reliabilityPercentage + " " + maxSpeedPercentage + " " + score);
	
	return score.tointeger()
}


function GetNumberOfAircraftToUse() {
	local populationPerAircraft = 1000;
	local maxNumberOfAircraftToUse = 10;
	local tempNumberOfAircraftToUse = ((AITown.GetPopulation(townToConnect.Begin()) + AITown.GetPopulation(townToConnect.Next())) / 2.00) / populationPerAircraft;
	return min(floor(tempNumberOfAircraftToUse + 0.5 ).tointeger(), maxNumberOfAircraftToUse);
}

function GetAirportToUse() {
	local airportTypeList = airportLib.GetAirportTypeList();
	
	airportTypeList.Valuate(AIAirport.IsAirportInformationAvailable);
	airportTypeList.KeepValue(1);
	airportTypeList.Valuate(AIAirport.IsValidAirportType);
	airportTypeList.KeepValue(1);
	
	foreach (airportType, _ in airportTypeList) {
	if (!airportLib.IsPlaneTypeAcceptedByAirportType(AIEngine.GetPlaneType(this.GetBestAircraft()),airportType)) airportTypeList.RemoveItem(airportType);
	}
	airportTypeList.Sort(AIList.SORT_BY_ITEM, false);
	
	return airportTypeList.Begin();
}


//Using function in SuperLib instead
//TODO: choose tile with most houses in coverage radius.
function BuildAirportAtTown(buildAtTown) {
	local currentTile = null;
	local airportWidth = AIAirport.GetAirportWidth(airportToUse);
	local airportHeight = AIAirport.GetAirportHeight(airportToUse);
	
	//AISign.BuildSign(AITown.GetLocation(buildAtTown), "Town");
	

	if(!_SuperLib_Town.TownRatingAllowStationBuilding(buildAtTown)) {
		AILog.Warning("Our rating at " + AITown.GetName(buildAtTown) + " is too low");
		return null;
	}
	local mode = AITestMode();
	spiralWalker.Start(AITown.GetLocation(buildAtTown));
	do {
		spiralWalker.Walk();
		currentTile = spiralWalker.GetTile();
		if (AITile.IsBuildableRectangle(currentTile, airportWidth, airportHeight)) {
			if (AIAirport.BuildAirport(currentTile, airportToUse, AIStation.STATION_NEW)) {
				mode = null;
				mode = AIExecMode();
				AIAirport.BuildAirport(currentTile, airportToUse, AIStation.STATION_NEW);
				spiralWalker.Reset();
				return currentTile;
			} else if (AITile.LevelTiles(currentTile, AIMap.GetTileIndex(AIMap.GetTileX(currentTile) + airportWidth, AIMap.GetTileY(currentTile) + airportHeight))) {
				mode = null;
				mode = AIExecMode();
				AITile.LevelTiles(currentTile, AIMap.GetTileIndex(AIMap.GetTileX(currentTile) + airportWidth, AIMap.GetTileY(currentTile) + airportHeight));
				if (AIAirport.BuildAirport(currentTile, airportToUse, AIStation.STATION_NEW)) {
					spiralWalker.Reset();
					return currentTile;
				}
			//AISign.BuildSign(currentTile, "1")
			}
		}
	} while (AITown.IsWithinTownInfluence(buildAtTown, currentTile));
	return null;
}