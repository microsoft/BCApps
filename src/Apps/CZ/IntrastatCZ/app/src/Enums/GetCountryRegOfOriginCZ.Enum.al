// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

/// <summary>
/// Defines where the Country/Region of Origin Code of the Intrastat report line is taken from.
/// To add a new mode, extend the enum with a value and set Implementation to a codeunit implementing "Intrastat Origin Mode CZ".
/// </summary>
enum 31302 "Get Country/Reg. of Origin CZ" implements "Intrastat Origin Mode CZ"
{
    Extensible = true;
    DefaultImplementation = "Intrastat Origin Mode CZ" = "Item Card Origin CZ";
    UnknownValueImplementation = "Intrastat Origin Mode CZ" = "Item Card Origin CZ";

    value(0; "Item Card")
    {
        Caption = 'Item Card';
        Implementation = "Intrastat Origin Mode CZ" = "Item Card Origin CZ";
    }
    value(1; "Posted Entries")
    {
        Caption = 'Posted Entries';
        Implementation = "Intrastat Origin Mode CZ" = "Posted Entries Origin CZ";
    }
}
