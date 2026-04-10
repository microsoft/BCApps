// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using System.Text;

codeunit 344 "County CaptionClass Mgmt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CountyTxt: Label 'County';
        SellToLbl: Label 'Sell-to %1', Comment = '%1 = County';
        BillToLbl: Label 'Bill-to %1', Comment = '%1 = County';
        ShipToLbl: Label 'Ship-to %1', Comment = '%1 = County';
        BuyFromLbl: Label 'Buy-from %1', Comment = '%1 = County';
        PayToLbl: Label 'Pay-to %1', Comment = '%1 = County';
        TransferFromLbl: Label 'Transfer-from %1', Comment = '%1 = County';
        TransferToLbl: Label 'Transfer-to %1', Comment = '%1 = County';
        SenderBankLbl: Label 'Sender Bank %1', Comment = '%1 = County';
        RecipientBankLbl: Label 'Recipient Bank %1', Comment = '%1 = County';
        RecipientLbl: Label 'Recipient %1', Comment = '%1 = County';
        CompanyLbl: Label 'Company %1', Comment = '%1 = County';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure ResolveCaptionClass(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea = '5' then
            Caption := CountyClassTranslate(CaptionExpr, Resolved);
    end;

    local procedure CountyClassTranslate(CaptionExpr: Text; var Resolved: Boolean): Text
    var
        CountryRegion: Record "Country/Region";
        CommaPosition: Integer;
        CountyCaptionType: Text[30];
        CountyCaptionRef: Text;
        UsageContext: Text;
    begin
        Resolved := false;
        CommaPosition := StrPos(CaptionExpr, ',');
        if CommaPosition > 0 then begin
            CountyCaptionType := CopyStr(CaptionExpr, 1, CommaPosition - 1);
            CountyCaptionRef := CopyStr(CaptionExpr, CommaPosition + 1);
            case CountyCaptionType of
                '2':
                    UsageContext := SellToLbl;
                '3':
                    UsageContext := BillToLbl;
                '4':
                    UsageContext := ShipToLbl;
                '5':
                    UsageContext := BuyFromLbl;
                '6':
                    UsageContext := PayToLbl;
                '7':
                    UsageContext := TransferFromLbl;
                '8':
                    UsageContext := TransferToLbl;
                '9':
                    UsageContext := SenderBankLbl;
                '10':
                    UsageContext := RecipientBankLbl;
                '11':
                    UsageContext := RecipientLbl;
                '12':
                    UsageContext := CompanyLbl;
            end;
            case CountyCaptionType of
                '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12':
                    begin
                        if CountyCaptionRef = '' then begin
                            Resolved := true;
                            if UsageContext <> '' then
                                exit(StrSubstNo(UsageContext, CountyTxt));
                            exit(CountyTxt);
                        end;
                        if CountryRegion.Get(CountyCaptionRef) then begin
                            Resolved := true;
                            if CountryRegion."County Name" <> '' then begin
                                if UsageContext <> '' then
                                    exit(StrSubstNo(UsageContext, CountryRegion."County Name"));
                                exit(CountryRegion."County Name");
                            end;
                            if UsageContext <> '' then
                                exit(StrSubstNo(UsageContext, CountyTxt));
                            exit(CountyTxt);
                        end;
                    end;
                else
                    exit(CountyTxt);
            end;
        end;
        exit(CountyTxt);
    end;
}

