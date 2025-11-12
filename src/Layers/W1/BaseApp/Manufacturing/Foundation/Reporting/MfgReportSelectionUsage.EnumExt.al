// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

enumextension 99000750 "Mfg. Report Selection Usage" extends "Report Selection Usage"
{
    value(19; "Prod.Order") { Caption = 'Production Order'; }
    value(22; "M1") { Caption = 'Job Card'; }
    value(23; "M2") { Caption = 'Mat. & Requisition'; }
    value(24; "M3") { Caption = 'Shortage List'; }
    value(25; "M4") { Caption = 'Gantt Chart'; }
    value(133; "Prod. Output Item Label") { Caption = 'Prod. Output Item Label'; }
}
