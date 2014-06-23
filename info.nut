class Trotter_AIr extends AIInfo {
  function GetAuthor()      { return "Thomas Lycett"; }
  function GetName()        { return "Trotter AIr"; }
  function GetDescription() { return "Placeholder"; }
  function GetVersion()     { return 1; }
  function GetDate()        { return "2012-01-16"; }
  function CreateInstance() { return "Trotter_AIr"; }
  function GetShortName()   { return "tAIr"; }
  function GetAPIVersion()  { return "1.0"; }
}

/* Tell the core we are an AI */
RegisterAI(Trotter_AIr());
