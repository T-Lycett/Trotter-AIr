class StationStats {
	
	airportLib = null;
	helper = null;
	airportTown = null;
	airportFullCapacityCount = null;
	airportLastEmptyAirspaceDate = null;
	townsWithoutAirports = null;
	aircraftLastTransferAirport = null;
	aircraftAirportBuiltAt = null;
	constructor() {
		airportLib = _SuperLib_Airport();
		helper = _SuperLib_Helper();
		airportTown = AIList();
		airportFullCapacityCount = AIList();
		airportLastEmptyAirspaceDate = AIList();
		townsWithoutAirports = AITownList();
		aircraftLastTransferAirport = AIList();
		aircraftAirportBuiltAt = AIList();
	}
	
}



function StationStats::InitializeAirport(airport, town) {
	
	townsWithoutAirports.RemoveItem(town);
	airportTown.AddItem(airport, town);
	airportFullCapacityCount.AddItem(airport, 0);
	airportLastEmptyAirspaceDate.AddItem(airport, 0);
	
	AILog.Warning("Initialize " + airport + " " + AIBaseStation.GetName(airport));
	
}



function StationStats::InitializeAircraft(aircraft, airportBuiltAt) {
	
	aircraftLastTransferAirport.AddItem(aircraft, airportBuiltAt);
	aircraftAirportBuiltAt.AddItem(aircraft, airportBuiltAt);
	
}



function StationStats::ResetAirportStats(airport) {
	
	airportFullCapacityCount.SetValue(airport, 0);
	
}


function StationStats::UpdateAirportStats() {
	
	local airportsOwned = AIStationList(AIStation.STATION_AIRPORT);
	
	foreach (airport, _ in airportsOwned) {
		local aircraftToCheck = this.GetVehiclesWithStationAsLastDestination(airport);
		
		foreach (aircraft, _ in aircraftToCheck) {
			if (aircraftLastTransferAirport.GetValue(aircraft) != airport) {
				local cargoID = AIEngine.GetCargoType(AIVehicle.GetEngineType(aircraft));
				
				if ((AIVehicle.GetCargoLoad(aircraft, cargoID) / AIVehicle.GetCapacity(aircraft, cargoID)) == 1) {
					airportFullCapacityCount.SetValue(airport, airportFullCapacityCount.GetValue(airport) + 1);
				} else {
					airportFullCapacityCount.SetValue(airport, 0);
				}
				
				aircraftLastTransferAirport.SetValue(aircraft, airport);
			}
		}
		
		if (airportLib.GetNumAircraftsInAirportQueue(airport) == 0) {
			airportLastEmptyAirspaceDate.SetValue(airport, AIDate.GetCurrentDate());
		}
	}
	
}



function StationStats::GetVehiclesWithStationAsLastDestination(station) {
	local vehicleStationList = AIVehicleList_Station(station);
	local vehicleList = AIList();
		foreach (vehicle, _ in vehicleStationList) {
		
		if (AIVehicle.GetState(vehicle) == AIVehicle.VS_RUNNING || AIVehicle.GetState(vehicle) == AIVehicle.VS_BROKEN) {
			if (AIOrder.ResolveOrderPosition(vehicle, AIOrder.ORDER_CURRENT) == 0) {
				if (AIOrder.GetOrderDestination(vehicle, AIOrder.GetOrderCount(vehicle) - 1) == AIBaseStation.GetLocation(station)) {
					vehicleList.AddItem(vehicle, 0);
				}
			} else if (AIOrder.ResolveOrderPosition(vehicle, AIOrder.ORDER_CURRENT) >= 1) {
				if (AIOrder.GetOrderDestination(vehicle, AIOrder.ResolveOrderPosition(vehicle, AIOrder.ORDER_CURRENT) - 1) == AIBaseStation.GetLocation(station)) {
					vehicleList.AddItem(vehicle, 0);
				}
			}
		}
	}
	return vehicleList;
}



function StationStats::GetAllAirportsConnectedToAirport(airport) {
	local airportsOwned = AIStationList(AIStation.STATION_AIRPORT);
	local aircraftForAirport =  AIVehicleList_Station(airport);
	local airportsConnected = AIList();
	airportsOwned.RemoveItem(airport);
	foreach (tempAirport, _ in airportsOwned) {
		local tempAircraftForTempAirport = AIVehicleList_Station(tempAirport);
		foreach (tempAircraft, _ in tempAircraftForTempAirport) {
			if (aircraftForAirport.HasItem(tempAircraft) && !airportsConnected.HasItem(tempAirport)) {
				airportsConnected.AddItem(tempAirport, 0);
				//AILog.Info(AIBaseStation.GetName(tempAirport) + " is connected to " + AIBaseStation.GetName(airport));
			}
		}
	}
	return airportsConnected;
}



function StationStats::GetTownOfAirport(airport) {
	if (airportTown.HasItem(airport)) {
		return airportTown.GetValue(airport);
	} else {
		return null;
	}
}


//Gets the sum of the capacity of every aircraft which has an order for the airport.
function StationStats::GetTotalAircraftCapacity(airport, PAXID) {
	local totalCapacity = 0;
	local aircraftWithAirportAsOrder = AIVehicleList_Station(airport);
	
	foreach (aircraft, _ in aircraftWithAirportAsOrder) {
		totalCapacity += AIVehicle.GetCapacity(aircraft, PAXID);
	}
	return totalCapacity;
}



function StationStats::GetAirportFullCapacityCount(airport) {
	
	return airportFullCapacityCount.GetValue(airport);

}



function StationStats::GetLastEmptyAirspaceDate(airport) {
	return airportLastEmptyAirspaceDate.GetValue(airport);
}



function StationStats::GetTownsWithoutAirports() {
	
	return townsWithoutAirports;
	
}



function StationStats::GetAircraftAirportBuiltAt(aircraft) {
	
	return aircraftAirportBuiltAt.GetValue(aircraft);
	
}