#pragma warning disable AA0247
namespace Microsoft.Integration.Shopify;

using System.AI;

/// <summary>
/// Codeunit Shpfy Tax Match Function (ID 30474).
/// Implements the AOAI Function interface for tax jurisdiction matching.
/// </summary>
codeunit 30474 "Shpfy Tax Match Function" implements "AOAI Function"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure GetPrompt() Prompt: JsonObject
    begin
        Prompt.ReadFrom(NavApp.GetResourceAsText('AITools/TaxMatchFunction-ToolDef.json', TextEncoding::UTF8));
    end;

    procedure Execute(Arguments: JsonObject): Variant
    begin
        exit(Arguments);
    end;

    procedure GetName(): Text
    begin
        exit(FunctionNameLbl);
    end;

    var
        FunctionNameLbl: Label 'match_tax_jurisdictions', Locked = true;
}
