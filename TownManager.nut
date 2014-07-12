class TownManager {
	
	spiralWalker = null;
	constructor() {
		spiralWalker = _MinchinWeb_SW_();
	}
}



function TownManager::AppeaseLocalAuthority(town, requiredRating) {
	
	if (AITown.GetRating(town, COMPANYID) == 0) return false;
	
	AILog.Info("appeasing local authority");
	
	if (AITown.GetRating(town, COMPANYID) <= requiredRating) {
			local tile = null;
			local iii = 0;
			
			AILog.Info("Planting trees at " + AITown.GetName(town) + " Rating: " + AITown.GetRating(town, COMPANYID));
			
			spiralWalker.Start(AITown.GetLocation(town));
			do {
				spiralWalker.Walk();
				tile = spiralWalker.GetTile();
				if (AITile.GetTownAuthority(tile) == town) {
					do {
					} while(AITile.PlantTree(tile));
				}
				iii++;
			} while (AITown.GetRating(town, COMPANYID) <= requiredRating && iii < 1000);
		}
		
		while (AITown.GetRating(town, COMPANYID) <= requiredRating) {
			AILog.Info("Bribing " + AITown.GetName(town) + " Rating: " + AITown.GetRating(town, COMPANYID));
			AITown.PerformTownAction(town, 7);
		}
	
}