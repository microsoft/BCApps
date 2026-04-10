// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

codeunit 3689 "Low-Level Code Parameter"
{
    var
        RunMode: Enum "Low-Level Code Run Mode";
        Window: Dialog;
        LastUpdate: DateTime;
        PopulatingBOMLbl: Label 'Populating BOM tree';
        CalculatingLbl: Label 'Calculating low- level codes';
        WritingToDBLbl: Label 'Writing to database';
        DialogContentTxt: Label '#1################## \\    #2##################################### \\    #3##################################### ', Comment = '%1 corresponds to the heading of the dialog, %2 corresponds to the BOM details, e.g. Type and No., %3 = counter info below';
        CounterTxt: Label 'Processed %1 of %2.', Comment = '%1 corresponds to the count of entities progressed, %2 correponds to total count of entities';

    procedure Create()
    begin
        Window.Open(DialogContentTxt);
        ShowHeading(PopulatingBOMLbl);
        LastUpdate := CurrentDateTime;
    end;

    procedure Close()
    begin
        Window.Close();
    end;

    procedure SetRunMode(NewRunMode: Enum "Low-Level Code Run Mode")
    begin
        RunMode := NewRunMode;
        case RunMode of
            RunMode::Calculate:
                ShowHeading(CalculatingLbl);
            RunMode::"Write To Database":
                ShowHeading(WritingToDBLbl);
        end;
    end;

    procedure GetRunMode(): Enum "Low-Level Code Run Mode"
    begin
        exit(RunMode);
    end;

    procedure ShowHeading(HeadingTxt: Text)
    begin
        Window.Update(1, HeadingTxt);
        Window.Update(2, '');
        Window.Update(3, '');
    end;

    procedure ShowDetails(DetailTxt: Text; Progressed: Integer; Total: Integer)
    begin
        if CurrentDateTime - LastUpdate < 2000 then
            exit;
        Window.Update(2, DetailTxt);
        if Total = 0 then
            Window.Update(3, '')
        else
            Window.Update(3, StrSubstNo(CounterTxt, Progressed, Total));
        LastUpdate := CurrentDateTime;
    end;

}