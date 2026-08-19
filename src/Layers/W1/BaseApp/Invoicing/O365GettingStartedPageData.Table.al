// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
table 1308 "O365 Getting Started Page Data"
{
    Caption = 'O365 Getting Started Page Data';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Display Target"; Code[20])
        {
            Caption = 'Display Target';
        }
        field(3; "Wizard ID"; Integer)
        {
            Caption = 'Wizard ID';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ',Image,Text';
            OptionMembers = ,Image,Text;
        }
        field(11; Image; Media)
        {
            Caption = 'Image';
        }
        field(12; "Body Text"; BLOB)
        {
            Caption = 'Body Text';
        }
        field(13; "Media Resources Ref"; Code[50])
        {
            Caption = 'Media Resources Ref';
        }
    }

    keys
    {
        key(Key1; "No.", "Display Target", "Wizard ID", Type)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        AllDisplayTargetsTxt: Label 'DEFAULT', Locked = true;
        ClientTypeManagement: Codeunit "Client Type Management";

    procedure GetPageBodyText(var O365GettingStartedPageData: Record "O365 Getting Started Page Data"; CurrentPageID: Integer; WizardID: Integer): Boolean
    begin
        Clear(O365GettingStartedPageData);
        O365GettingStartedPageData.SetRange("No.", CurrentPageID);
        O365GettingStartedPageData.SetRange("Wizard ID", WizardID);
        O365GettingStartedPageData.SetRange(Type, Type::Text);
        O365GettingStartedPageData.SetAutoCalcFields("Body Text");

        exit(GetPageDataForCurrentDisplayTarget(O365GettingStartedPageData));
    end;

    procedure GetPageImage(var ImageO365GettingStartedPageData: Record "O365 Getting Started Page Data"; CurrentPageID: Integer; WizardID: Integer)
    begin
        Clear(ImageO365GettingStartedPageData);
        ImageO365GettingStartedPageData.SetFilter("No.", StrSubstNo('<=%1', CurrentPageID));
        ImageO365GettingStartedPageData.SetRange("Wizard ID", WizardID);
        ImageO365GettingStartedPageData.SetRange(Type, Type::Image);

        GetPageDataForCurrentDisplayTarget(ImageO365GettingStartedPageData);
    end;

    local procedure GetPageDataForCurrentDisplayTarget(var O365GettingStartedPageData: Record "O365 Getting Started Page Data"): Boolean
    begin
        O365GettingStartedPageData.SetFilter("Display Target", StrSubstNo('*%1*', Format(ClientTypeManagement.GetCurrentClientType())));

        if not O365GettingStartedPageData.FindLast() then begin
            O365GettingStartedPageData.SetRange("Display Target", AllDisplayTargetsTxt);
            if not O365GettingStartedPageData.FindLast() then
                exit(false);
        end;

        exit(true);
    end;
}

