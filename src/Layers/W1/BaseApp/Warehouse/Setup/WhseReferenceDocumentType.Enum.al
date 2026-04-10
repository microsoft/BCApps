// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

enum 5779 "Whse. Reference Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Posted Rcpt.") { Caption = 'Posted Receipt'; }
    value(2; "Posted P. Inv.") { Caption = 'Posted P. Invoice'; }
    value(3; "Posted Rtrn. Rcpt.") { Caption = 'Posted Return Receipt'; }
    value(4; "Posted P. Cr. Memo") { Caption = 'Posted P. Credit Memo'; }
    value(5; "Posted Shipment") { Caption = 'Posted Shipment'; }
    value(6; "Posted S. Inv.") { Caption = 'Posted S. Invoice'; }
    value(7; "Posted Rtrn. Shipment") { Caption = 'Posted Return Shipment'; }
    value(8; "Posted S. Cr. Memo") { Caption = 'Posted S. Credit Memo'; }
    value(9; "Posted T. Receipt") { Caption = 'Posted Transfer Receipt'; }
    value(10; "Posted T. Shipment") { Caption = 'Posted Transfer Shipment'; }
    value(11; "Item Journal") { Caption = 'Item Journal'; }
    // Implemented in enum extension Mfg. Whse. Reference Doc Type
    // value(12; "Prod.") { Caption = 'Production'; }
    value(13; "Put-away") { Caption = 'Put-away'; }
    value(14; Pick) { Caption = 'Pick'; }
    value(15; Movement) { Caption = 'Movement'; }
    value(16; "BOM Journal") { Caption = 'BOM Journal'; }
    value(17; "Job Journal") { Caption = 'Project Journal'; }
    // Implemented in enum extension Asm. Whse. Reference Doc Type
    // value(18; "Assembly") { Caption = 'Assembly'; }
}
