/**
 * Info file for Strategic Industry Placer GameScript
 */

class IndustryPlacer extends GSInfo {
    function GetAuthor()        { return "Perfk"; }
    function GetName()          { return "Strategic Industry Placer"; }
    function GetDescription()   { return "Advanced strategy-based industry placement system with 11 terrain strategies and distance control. Perfect for scenario creators."; }
    function GetVersion()       { return 1; }
    function GetDate()          { return "2025-10-26"; }
    function CreateInstance()   { return "IndustryPlacer"; }
    function GetShortName()     { return "SIPA"; }
    function GetAPIVersion()    { return "15"; }
    function GetUrl()           { return ""; }
    
    function GetSettings() {
        // You could add settings here to make the script more configurable
    }
}

RegisterGS(IndustryPlacer());
