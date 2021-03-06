//sup_convoy.sqf by Jigsor

sleep 2;
private ["_newZone","_type","_rnum","_objmkr","_cone","_VarName","_grp","_handle","_obj_leader","_stat_grp","_wp","_tskW","_tasktopicW","_taskdescW","_tskE","_tasktopicE","_taskdescE","_VehType","_vehicle1","_newPos","_veh1","_vehicle2","_veh2","_vehicle3","_veh3","_vehicle4","_veh4","_handle1","_allVeh","_range"];

_newZone = _this select 0;
_type = _this select 1;
_rnum = str(round (random 999));
_range = 600;

/*
//Move Zone to Road
private ["_roadNear","_roadSegment","_roadDir"];
_roads = _newZone nearRoads 100;
if (count _roads > 0) then {
	_roadNear = true;
	_roadSegment = _roads select 0;
	_roadDir = direction _roadSegment;
	while {!isOnRoad _newZone} do {
	_roadPos = _newZone findEmptyPosition [2, 100, _type];
	sleep 0.2;
	};
	_newZone = _roadPos;
};
*/

objective_pos_logic setPos _newZone;

_objmkr = createMarker ["ObjectiveMkr", _newZone];
"ObjectiveMkr" setMarkerShape "ELLIPSE";
"ObjectiveMkr" setMarkerSize [2, 2];
"ObjectiveMkr" setMarkerShape "ICON";
"ObjectiveMkr" setMarkerType "mil_dot";
"ObjectiveMkr" setMarkerColor "ColorRed";
"ObjectiveMkr" setMarkerText "Supply Convoy";

// Spawn Objective center object
_cone = createVehicle [_type, _newZone, [], 0, "None"];//Vanilla
sleep jig_tvt_globalsleep;
_cone setVectorUp [0,0,1];

// Spawn Objective enemy deffences
_grp = [_newZone,14] call spawn_Op4_grp;
_stat_grp = [_newZone,3] call spawn_Op4_StatDef;

_stat_grp setCombatMode "RED";

_handle=[_grp, position objective_pos_logic, 75] call BIS_fnc_taskPatrol;

//Spawn Convoy
sconvoy_grp = createGroup INS_Op4_side;

_newPos = [getMarkerPos "ObjectiveMkr", 0, 50, 10, 0, 0.6, 0] call BIS_fnc_findSafePos;
_VehType = INS_Op4_Veh_Support select 0;
_vehicle1 = [_newPos, 0, _VehType, sconvoy_grp] call BIS_fnc_spawnvehicle;
sleep 1;
_veh1 = _vehicle1 select 0;

_newPos = [getMarkerPos "ObjectiveMkr", 0, 50, 10, 0, 0.6, 0] call BIS_fnc_findSafePos;
_VehType = INS_Op4_Veh_Support select 1;
_vehicle2 = [_newPos, 0, _VehType, sconvoy_grp] call BIS_fnc_spawnvehicle;
sleep 1;
_veh2 = _vehicle2 select 0;

_newPos = [getMarkerPos "ObjectiveMkr", 0, 50, 10, 0, 0.6, 0] call BIS_fnc_findSafePos;
_VehType = INS_Op4_Veh_Support select 2;
_vehicle3 = [_newPos, 0, _VehType, sconvoy_grp] call BIS_fnc_spawnvehicle;
sleep 1;
_veh3 = _vehicle3 select 0;

_newPos = [getMarkerPos "ObjectiveMkr", 0, 50, 10, 0, 0.6, 0] call BIS_fnc_findSafePos;
_VehType = INS_Op4_Veh_Support select 3;
_vehicle4 = [_newPos, 0, _VehType, sconvoy_grp] call BIS_fnc_spawnvehicle;
sleep 1;
_veh4 = _vehicle4 select 0;

_allVeh = [_veh1,_veh2,_veh3,_veh4];
{_x addeventhandler ["killed","[(_this select 0)] spawn remove_carcass_fnc"]} forEach (units sconvoy_grp);
{_x addeventhandler ["killed","[(_this select 0)] spawn remove_carcass_fnc"]} forEach _allVeh;

{[_x] call anti_collision} foreach _allVeh;
{_x setVariable["persistent",true]} foreach _allVeh;
//{[_x] allowCrewInImmobile true} foreach _allVeh;

// convoy movement
_handle1=[sconvoy_grp, position objective_pos_logic, _range] call Veh_taskPatrol_mod;
if (DebugEnabled > 0) then {[sconvoy_grp] spawn INS_Tsk_GrpMkrs;};

// create west task
_tskW = "tskW_destroy_convoy" + _rnum;
_tasktopicW = localize "STR_BMR_Tsk_topicW_dsc";
_taskdescW = localize "STR_BMR_Tsk_descW_dsc";
[_tskW,_tasktopicW,_taskdescW,WEST,[],"created",_newZone] call SHK_Taskmaster_add;
sleep 5;

// create east task
_tskE = "tskE_defend_convoy" + _rnum;
_tasktopicE = localize "STR_BMR_Tsk_topicE_dsc";
_taskdescE = localize "STR_BMR_Tsk_descE_dsc";
[_tskE,_tasktopicE,_taskdescE,EAST,[],"created",_newZone] call SHK_Taskmaster_add;

waitUntil {{alive _x} count units sconvoy_grp > 0};
sleep 0.1;

if (INS_environment isEqualTo 1) then {if (daytime > 3.00 && daytime < 5.00) then {[] spawn {[[], "INS_fog_effect"] call BIS_fnc_mp;};};};

// Only one outcome supported.
waitUntil {{alive _x} count units sconvoy_grp < 1};

[_tskW, "succeeded"] call SHK_Taskmaster_upd;
[_tskE, "failed"] call SHK_Taskmaster_upd;

// clean up
"ObjectiveMkr" setMarkerAlpha 0;
sleep 90;

{deleteVehicle _x; sleep 0.1} forEach (units _grp);
{deleteVehicle _x; sleep 0.1} forEach (units _stat_grp);
deleteGroup _grp;
deleteGroup _stat_grp;
deleteGroup sconvoy_grp;

if (!isNull _cone) then {deleteVehicle _cone; sleep 0.1;};
{if (!isNull _x) then {deleteVehicle _x; sleep 0.1}} foreach _allVeh;
{if (typeof _x in INS_Op4_stat_weps) then {deleteVehicle _x; sleep 0.1}} forEach (NearestObjects [objective_pos_logic, [], 40]);

deleteMarker "ObjectiveMkr";

if (true) exitWith {sleep 20; nul = [] execVM "Objectives\random_objectives.sqf";};