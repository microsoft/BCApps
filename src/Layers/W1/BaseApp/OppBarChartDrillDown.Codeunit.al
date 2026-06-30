// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 5050 "Opp. Bar Chart DrillDown"
{
    TableNo = "Bar Chart Buffer";

    trigger OnRun()
    begin
        if Rec.Tag = '' then
            Error(FilterTooLongErr);
        OpportunityEntry.SetView(Rec.Tag);
        OpportunityEntry.SetRange(Active, true);
        if OpportunityEntry.Find('-') then
            repeat
                Opportunity.Get(OpportunityEntry."Opportunity No.");
                TempOpportunity := Opportunity;
                TempOpportunity.Insert();
            until OpportunityEntry.Next() = 0;

        PAGE.Run(PAGE::"Active Opportunity List", TempOpportunity);
    end;

    var
        FilterTooLongErr: Label 'The corresponding opportunity entries cannot be displayed because the filter expression is too long.';
        OpportunityEntry: Record "Opportunity Entry";
        Opportunity: Record Opportunity;
        TempOpportunity: Record Opportunity temporary;
}

