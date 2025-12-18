// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

table 6120 "E-Doc Sample Purch. Inv File"
{
    Access = Internal;
    Caption = 'E-Doc Sample Purchase Invoice File';
    DataClassification = CustomerContent;
    LookupPageId = "E-Doc Sample Purch. Inv. Files";
    DrillDownPageId = "E-Doc Sample Purch. Inv. Files";
    ReplicateData = false;

    fields
    {
        field(1; "File Name"; Text[100])
        {
            Caption = 'File Name';
        }
        field(2; "File Content"; Blob)
        {
            Caption = 'File Content';
        }
        field(3; Scenario; Text[2048])
        {
            Caption = 'Scenario';
        }
        field(4; "Vendor Name"; Text[1024])
        {
            Caption = 'Vendor Name';
            ToolTip = 'Specifies the name of the vendor associated with the demo file.';
        }
    }
}