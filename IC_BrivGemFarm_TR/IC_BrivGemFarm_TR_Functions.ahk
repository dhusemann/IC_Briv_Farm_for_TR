;v0.432
#include %A_LineFile%\..\IC_BrivGemFarm_TR_PrevReset.ahk
global PrevRSTobject = new TR_Prev_Reset

class TRClass extends IC_BrivGemFarm_Class
{
    TestForSteelBonesStackFarming()
    {
;				    msgbox "TEST TRSTACK modified"

        CurrentZone := g_SF.Memory.ReadCurrentZone()
        stacks := g_SF.Memory.ReadSBStacks()
        stackfail := 0
        forcedReset := false
        forcedResetReason := ""

	
		;Early stacking
		if ( g_BrivUserSettings[ "EarlyStacking" ] AND stacks < g_BrivUserSettings[ "TargetStacks" ] AND CurrentZone > g_BrivUserSettings[ "StackZone" ] AND g_SF.Memory.ReadHasteStacks() > g_BrivUserSettings[ "TRHaste" ]  )
			{
				this.StackFarm()
			}
			
		;End of run stacking		
		if ( g_SF.Memory.ReadHasteStacks() < 50 AND g_SF.Memory.ReadHighestZone() > 10 AND CurrentZone > g_BrivUserSettings[ "MinStackZone" ] )
			{
			PrevRSTobject.setPrevReset(CurrentZone)
			this.StackFarm()
			g_SF.RestartAdventure( "TR reset" )
			}
			
		;Forced reset
		if ( g_BrivUserSettings [ "TRForce" ] AND g_BrivUserSettings [ "TRForceZone" ] < CurrentZone AND CurrentZone > g_BrivUserSettings[ "MinStackZone" ] )
			{
			PrevRSTobject.setPrevReset(CurrentZone)
			this.StackFarm()
			g_SF.RestartAdventure( "TR forced reset" )
			}

	}
	
	StackFarm()
    {
        if ( g_BrivUserSettings[ "RestartStackTime" ] AND stacks < g_BrivUserSettings[ "TargetStacks" ] )
            this.StackRestart()
        else if (stacks < g_BrivUserSettings[ "TargetStacks" ])
            this.StackNormal()
        currentFormation := g_SF.Memory.GetCurrentFormation()
        isShandieInFormation := g_SF.IsChampInFormation( 47, currentFormation )
        if ( g_BrivUserSettings[ "EarlyStacking" ] AND isShandieInFormation AND g_BrivUserSettings[ "EarlyDashWait" ] ) ; AND g_SF.Memory.ReadHighestZone() + 50 < g_BrivUserSettings[ "StackZone"] )
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
    }
	
	StackRestart()
    {
        stacks := g_SF.Memory.ReadSBStacks()
        i := 0
        while ( stacks < g_BrivUserSettings[ "TargetStacks" ] AND i < 10 )
        {
            ++i
            this.StackFarmSetup()
            formationArray := g_SF.Memory.GetCurrentFormation()
            g_SF.CloseIC( "StackRestart" )
            StartTime := A_TickCount
            ElapsedTime := 0
            g_SharedData.LoopString := "Stack Sleep"
            var := ""
            if ( g_BrivUserSettings[ "DoChests" ] AND formationArray != "" )
            {
                startTime := A_TickCount
                if(g_BrivUserSettings[ "DoChestsContinuous" ])
                {
                    while(g_BrivUserSettings[ "RestartStackTime" ] > ( A_TickCount - startTime ))
                    {
                        var .= this.BuyOrOpenChests(startTime) . "`n"
                    }
                }
                else
                {
                    var := this.BuyOrOpenChests() . " "
                }
                ElapsedTime := A_TickCount - StartTime
                g_SharedData.LoopString := "Sleep: " . var
            }
            while ( ElapsedTime < g_BrivUserSettings[ "RestartStackTime" ] )
            {
                ElapsedTime := A_TickCount - StartTime
                g_SharedData.LoopString := "Stack Sleep: " . g_BrivUserSettings[ "RestartStackTime" ] - ElapsedTime . var
            }
            g_SF.SafetyCheck()
            stacks := g_SF.Memory.ReadSBStacks() ; Update GUI and Globals
            ;check if save reverted back to below stacking conditions
            if ( g_SF.Memory.ReadCurrentZone() < g_BrivUserSettings[ "MinStackZone" ] )
            {
                Break  ; "Bad Save? Loaded below stack zone, see value."
            }
        }
        g_PreviousZoneStartTime := A_TickCount
        return
    }
}
