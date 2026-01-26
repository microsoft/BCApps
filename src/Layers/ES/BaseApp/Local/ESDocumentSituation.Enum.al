// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

enum 10727 "ES Document Situation"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Posted BG/PO") { Caption = 'Posted BG/PO'; }
    value(2; "Closed BG/PO") { Caption = 'Closed BG/PO'; }
    value(3; "BG/PO") { Caption = 'BG/PO'; }
    value(4; "Cartera") { Caption = 'Cartera'; }
    value(5; "Closed Documents") { Caption = 'Closed Documents'; }
}