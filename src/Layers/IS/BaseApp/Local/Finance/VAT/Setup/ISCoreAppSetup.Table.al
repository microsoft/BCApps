#if not CLEANSCHEMA27 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

table 10903 "IS Core App Setup"
{
    Caption = 'Iceland Core App Setup';
    ObsoleteReason = 'Used to enable the IS Core App.';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[10])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure IsEnabled(): Boolean
    var
        ISCoreAppSetup: Record "IS Core App Setup";
    begin
        if not ISCoreAppSetup.Get() then begin
            ISCoreAppSetup.Init();
            ISCoreAppSetup.Enabled := false;
            ISCoreAppSetup.Insert();
            Commit();
        end;
        exit(ISCoreAppSetup.Enabled);
    end;
}
 
#endif