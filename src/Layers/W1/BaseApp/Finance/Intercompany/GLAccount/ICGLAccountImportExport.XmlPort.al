// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.GLAccount;

using System.Telemetry;

xmlport 10 "IC G/L Account Import/Export"
{
    Caption = 'IC G/L Account Import/Export';

    schema
    {
        textelement(GLAccounts)
        {
            tableelement(icglacc; "IC G/L Account")
            {
                XmlName = 'ICGLAccount';
                fieldattribute(No; ICGLAcc."No.")
                {
                }
                fieldattribute(Name; ICGLAcc.Name)
                {
                }
                fieldattribute(AccountType; ICGLAcc."Account Type")
                {
                }
                fieldattribute(IncomeBalance; ICGLAcc."Income/Balance")
                {
                }
                fieldattribute(Blocked; ICGLAcc.Blocked)
                {
                }
                fieldattribute(Indentation; ICGLAcc.Indentation)
                {
                }

                trigger OnBeforeInsertRecord()
                var
                    OrgICGLAcc: Record "IC G/L Account";
                begin
                    XMLInbound := true;

                    if TempICGLAcc.Get(ICGLAcc."No.") then begin
                        if (ICGLAcc.Name <> TempICGLAcc.Name) or (ICGLAcc."Account Type" <> TempICGLAcc."Account Type") or
                           (ICGLAcc."Income/Balance" <> TempICGLAcc."Income/Balance") or (ICGLAcc.Blocked <> TempICGLAcc.Blocked)
                        then
                            Modified := Modified + 1;
                        ICGLAcc."Map-to G/L Acc. No." := TempICGLAcc."Map-to G/L Acc. No.";
                        OrgICGLAcc.Get(ICGLAcc."No.");
                        OrgICGLAcc.Delete();
                        TempICGLAcc.Delete();
                    end else
                        Inserted := Inserted + 1;
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPostXmlPort()
    var
        OrgICGLAcc: Record "IC G/L Account";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        MsgTxt: Text[1024];
    begin
        FeatureTelemetry.LogUptake('0000IKS', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000IKT', ICMapping.GetFeatureTelemetryName(), 'IC GL Account Import/Export');

        if XMLInbound then begin
            if TempICGLAcc.Find('-') then
                repeat
                    Deleted := Deleted + 1;
                    OrgICGLAcc.Get(TempICGLAcc."No.");
                    OrgICGLAcc.Delete();
                until TempICGLAcc.Next() = 0;

            if Inserted > 0 then
                if Inserted = 1 then
                    MsgTxt := StrSubstNo(Text001, Inserted, OrgICGLAcc.TableCaption())
                else
                    MsgTxt := StrSubstNo(Text002, Inserted);

            if Modified > 0 then begin
                if MsgTxt <> '' then
                    MsgTxt := MsgTxt + '\';
                if Modified = 1 then
                    MsgTxt := MsgTxt + StrSubstNo(Text003, Modified, OrgICGLAcc.TableCaption())
                else
                    MsgTxt := MsgTxt + StrSubstNo(Text004, Modified);
            end;

            if Deleted > 0 then begin
                if MsgTxt <> '' then
                    MsgTxt := MsgTxt + '\';
                if Deleted = 1 then
                    MsgTxt := MsgTxt + StrSubstNo(Text005, Deleted, OrgICGLAcc.TableCaption())
                else
                    MsgTxt := MsgTxt + StrSubstNo(Text006, Deleted);
            end;

            if Inserted + Deleted + Modified = 0 then
                MsgTxt := Text000;

            Message(MsgTxt);
        end;
    end;

    trigger OnPreXmlPort()
    var
        ICGLAcc: Record "IC G/L Account";
    begin
        TempICGLAcc.DeleteAll();
        if ICGLAcc.Find('-') then
            repeat
                TempICGLAcc := ICGLAcc;
                TempICGLAcc.Insert();
            until ICGLAcc.Next() = 0;
    end;

    var
        TempICGLAcc: Record "IC G/L Account" temporary;
        XMLInbound: Boolean;
        Inserted: Integer;
        Deleted: Integer;
        Modified: Integer;
#pragma warning disable AA0074
        Text000: Label 'There were no changes.';
#pragma warning disable AA0470
        Text001: Label '%1 %2 was added.';
        Text002: Label '%1 IC G/L Accounts were added.';
        Text003: Label '%1 %2 was updated.';
        Text004: Label '%1 IC G/L Accounts were updated.';
        Text005: Label '%1 %2 was deleted.';
        Text006: Label '%1 IC G/L Accounts were deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

