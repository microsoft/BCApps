// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Security.User;
using System.Utilities;

report 600 "Approval User Setup Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './OtherCapabilities/Approvals/ApprovalUserSetupTest.rdlc';
    Caption = 'Approval User Setup Test';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Test_Approval_SetupCaption; Test_Approval_SetupCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            dataitem("Sales Approval"; "User Setup")
            {
                DataItemTableView = sorting("User ID");
                column(SalesApprovalRoute_1_1_; SalesApprovalRoute[1, 1])
                {
                }
                column(SalesApprovalRoute_1_2_; SalesApprovalRoute[1, 2])
                {
                }
                column(SalesApprovalRoute_1_3_; SalesApprovalRoute[1, 3])
                {
                }
                column(SalesApprovalRoute_1_5_; SalesApprovalRoute[1, 5])
                {
                }
                column(SalesApprovalRoute_1_4_; SalesApprovalRoute[1, 4])
                {
                }
                column(SalesApprovalRoute_1_6_; SalesApprovalRoute[1, 6])
                {
                }
                column(SalesApprovalRoute_1_7_; SalesApprovalRoute[1, 7])
                {
                }
                column(SalesApprovalRoute_2_5_; SalesApprovalRoute[2, 5])
                {
                }
                column(SalesApprovalRoute_2_4_; SalesApprovalRoute[2, 4])
                {
                }
                column(SalesApprovalRoute_2_3_; SalesApprovalRoute[2, 3])
                {
                }
                column(SalesApprovalRoute_2_2_; SalesApprovalRoute[2, 2])
                {
                }
                column(SalesApprovalRoute_2_1_; SalesApprovalRoute[2, 1])
                {
                }
                column(SalesApprovalRoute_2_6_; SalesApprovalRoute[2, 6])
                {
                }
                column(SalesApprovalRoute_2_7_; SalesApprovalRoute[2, 7])
                {
                }
                column(SalesApprovalRoute_3_5_; SalesApprovalRoute[3, 5])
                {
                }
                column(SalesApprovalRoute_3_1_; SalesApprovalRoute[3, 1])
                {
                }
                column(SalesApprovalRoute_3_2_; SalesApprovalRoute[3, 2])
                {
                }
                column(SalesApprovalRoute_3_3_; SalesApprovalRoute[3, 3])
                {
                }
                column(SalesApprovalRoute_3_4_; SalesApprovalRoute[3, 4])
                {
                }
                column(SalesApprovalRoute_3_6_; SalesApprovalRoute[3, 6])
                {
                }
                column(SalesApprovalRoute_3_7_; SalesApprovalRoute[3, 7])
                {
                }
                column(SalesApprovalRoute_4_5_; SalesApprovalRoute[4, 5])
                {
                }
                column(SalesApprovalRoute_4_4_; SalesApprovalRoute[4, 4])
                {
                }
                column(SalesApprovalRoute_4_3_; SalesApprovalRoute[4, 3])
                {
                }
                column(SalesApprovalRoute_4_2_; SalesApprovalRoute[4, 2])
                {
                }
                column(SalesApprovalRoute_4_1_; SalesApprovalRoute[4, 1])
                {
                }
                column(SalesApprovalRoute_4_6_; SalesApprovalRoute[4, 6])
                {
                }
                column(SalesApprovalRoute_4_7_; SalesApprovalRoute[4, 7])
                {
                }
                column(SalesApprovalRoute_5_5_; SalesApprovalRoute[5, 5])
                {
                }
                column(SalesApprovalRoute_5_4_; SalesApprovalRoute[5, 4])
                {
                }
                column(SalesApprovalRoute_5_3_; SalesApprovalRoute[5, 3])
                {
                }
                column(SalesApprovalRoute_5_2_; SalesApprovalRoute[5, 2])
                {
                }
                column(SalesApprovalRoute_5_1_; SalesApprovalRoute[5, 1])
                {
                }
                column(SalesApprovalRoute_5_6_; SalesApprovalRoute[5, 6])
                {
                }
                column(SalesApprovalRoute_5_7_; SalesApprovalRoute[5, 7])
                {
                }
                column(SalesApprovalRoute_6_5_; SalesApprovalRoute[6, 5])
                {
                }
                column(SalesApprovalRoute_6_4_; SalesApprovalRoute[6, 4])
                {
                }
                column(SalesApprovalRoute_6_3_; SalesApprovalRoute[6, 3])
                {
                }
                column(SalesApprovalRoute_6_2_; SalesApprovalRoute[6, 2])
                {
                }
                column(SalesApprovalRoute_6_1_; SalesApprovalRoute[6, 1])
                {
                }
                column(SalesApprovalRoute_6_6_; SalesApprovalRoute[6, 6])
                {
                }
                column(SalesApprovalRoute_6_7_; SalesApprovalRoute[6, 7])
                {
                }
                column(SalesApprovalRoute_7_5_; SalesApprovalRoute[7, 5])
                {
                }
                column(SalesApprovalRoute_7_4_; SalesApprovalRoute[7, 4])
                {
                }
                column(SalesApprovalRoute_7_3_; SalesApprovalRoute[7, 3])
                {
                }
                column(SalesApprovalRoute_7_2_; SalesApprovalRoute[7, 2])
                {
                }
                column(SalesApprovalRoute_7_1_; SalesApprovalRoute[7, 1])
                {
                }
                column(SalesApprovalRoute_7_6_; SalesApprovalRoute[7, 6])
                {
                }
                column(SalesApprovalRoute_7_7_; SalesApprovalRoute[7, 7])
                {
                }
                column(SalesApprovalRoute_8_6_; SalesApprovalRoute[8, 6])
                {
                }
                column(SalesApprovalRoute_8_5_; SalesApprovalRoute[8, 5])
                {
                }
                column(SalesApprovalRoute_8_7_; SalesApprovalRoute[8, 7])
                {
                }
                column(SalesApprovalRoute_8_4_; SalesApprovalRoute[8, 4])
                {
                }
                column(SalesApprovalRoute_8_3_; SalesApprovalRoute[8, 3])
                {
                }
                column(SalesApprovalRoute_8_2_; SalesApprovalRoute[8, 2])
                {
                }
                column(SalesApprovalRoute_8_1_; SalesApprovalRoute[8, 1])
                {
                }
                column(SalesApprovalRoute_9_6_; SalesApprovalRoute[9, 6])
                {
                }
                column(SalesApprovalRoute_9_5_; SalesApprovalRoute[9, 5])
                {
                }
                column(SalesApprovalRoute_9_7_; SalesApprovalRoute[9, 7])
                {
                }
                column(SalesApprovalRoute_9_4_; SalesApprovalRoute[9, 4])
                {
                }
                column(SalesApprovalRoute_9_3_; SalesApprovalRoute[9, 3])
                {
                }
                column(SalesApprovalRoute_9_2_; SalesApprovalRoute[9, 2])
                {
                }
                column(SalesApprovalRoute_9_1_; SalesApprovalRoute[9, 1])
                {
                }
                column(SalesApprovalRoute_10_6_; SalesApprovalRoute[10, 6])
                {
                }
                column(SalesApprovalRoute_10_5_; SalesApprovalRoute[10, 5])
                {
                }
                column(SalesApprovalRoute_10_7_; SalesApprovalRoute[10, 7])
                {
                }
                column(SalesApprovalRoute_10_4_; SalesApprovalRoute[10, 4])
                {
                }
                column(SalesApprovalRoute_10_3_; SalesApprovalRoute[10, 3])
                {
                }
                column(SalesApprovalRoute_10_2_; SalesApprovalRoute[10, 2])
                {
                }
                column(SalesApprovalRoute_10_1_; SalesApprovalRoute[10, 1])
                {
                }
                column(SalesApprovalRoute_11_6_; SalesApprovalRoute[11, 6])
                {
                }
                column(SalesApprovalRoute_11_5_; SalesApprovalRoute[11, 5])
                {
                }
                column(SalesApprovalRoute_11_7_; SalesApprovalRoute[11, 7])
                {
                }
                column(SalesApprovalRoute_11_4_; SalesApprovalRoute[11, 4])
                {
                }
                column(SalesApprovalRoute_11_3_; SalesApprovalRoute[11, 3])
                {
                }
                column(SalesApprovalRoute_11_2_; SalesApprovalRoute[11, 2])
                {
                }
                column(SalesApprovalRoute_11_1_; SalesApprovalRoute[11, 1])
                {
                }
                column(SalesApprovalRoute_12_6_; SalesApprovalRoute[12, 6])
                {
                }
                column(SalesApprovalRoute_12_5_; SalesApprovalRoute[12, 5])
                {
                }
                column(SalesApprovalRoute_12_7_; SalesApprovalRoute[12, 7])
                {
                }
                column(SalesApprovalRoute_12_4_; SalesApprovalRoute[12, 4])
                {
                }
                column(SalesApprovalRoute_12_3_; SalesApprovalRoute[12, 3])
                {
                }
                column(SalesApprovalRoute_12_2_; SalesApprovalRoute[12, 2])
                {
                }
                column(SalesApprovalRoute_12_1_; SalesApprovalRoute[12, 1])
                {
                }
                column(SalesApprovalRoute_13_6_; SalesApprovalRoute[13, 6])
                {
                }
                column(SalesApprovalRoute_13_5_; SalesApprovalRoute[13, 5])
                {
                }
                column(SalesApprovalRoute_13_7_; SalesApprovalRoute[13, 7])
                {
                }
                column(SalesApprovalRoute_13_4_; SalesApprovalRoute[13, 4])
                {
                }
                column(SalesApprovalRoute_13_3_; SalesApprovalRoute[13, 3])
                {
                }
                column(SalesApprovalRoute_13_2_; SalesApprovalRoute[13, 2])
                {
                }
                column(SalesApprovalRoute_13_1_; SalesApprovalRoute[13, 1])
                {
                }
                column(SalesApprovalRoute_14_6_; SalesApprovalRoute[14, 6])
                {
                }
                column(SalesApprovalRoute_14_5_; SalesApprovalRoute[14, 5])
                {
                }
                column(SalesApprovalRoute_14_7_; SalesApprovalRoute[14, 7])
                {
                }
                column(SalesApprovalRoute_14_4_; SalesApprovalRoute[14, 4])
                {
                }
                column(SalesApprovalRoute_14_3_; SalesApprovalRoute[14, 3])
                {
                }
                column(SalesApprovalRoute_14_2_; SalesApprovalRoute[14, 2])
                {
                }
                column(SalesApprovalRoute_14_1_; SalesApprovalRoute[14, 1])
                {
                }
                column(SalesApprovalRoute_15_6_; SalesApprovalRoute[15, 6])
                {
                }
                column(SalesApprovalRoute_15_5_; SalesApprovalRoute[15, 5])
                {
                }
                column(SalesApprovalRoute_15_7_; SalesApprovalRoute[15, 7])
                {
                }
                column(SalesApprovalRoute_15_4_; SalesApprovalRoute[15, 4])
                {
                }
                column(SalesApprovalRoute_15_3_; SalesApprovalRoute[15, 3])
                {
                }
                column(SalesApprovalRoute_15_2_; SalesApprovalRoute[15, 2])
                {
                }
                column(SalesApprovalRoute_15_1_; SalesApprovalRoute[15, 1])
                {
                }
                column(SalesApprovalRoute_16_6_; SalesApprovalRoute[16, 6])
                {
                }
                column(SalesApprovalRoute_16_5_; SalesApprovalRoute[16, 5])
                {
                }
                column(SalesApprovalRoute_16_7_; SalesApprovalRoute[16, 7])
                {
                }
                column(SalesApprovalRoute_16_4_; SalesApprovalRoute[16, 4])
                {
                }
                column(SalesApprovalRoute_16_3_; SalesApprovalRoute[16, 3])
                {
                }
                column(SalesApprovalRoute_16_2_; SalesApprovalRoute[16, 2])
                {
                }
                column(SalesApprovalRoute_16_1_; SalesApprovalRoute[16, 1])
                {
                }
                column(SalesApprovalRoute_17_6_; SalesApprovalRoute[17, 6])
                {
                }
                column(SalesApprovalRoute_17_5_; SalesApprovalRoute[17, 5])
                {
                }
                column(SalesApprovalRoute_17_7_; SalesApprovalRoute[17, 7])
                {
                }
                column(SalesApprovalRoute_17_4_; SalesApprovalRoute[17, 4])
                {
                }
                column(SalesApprovalRoute_17_3_; SalesApprovalRoute[17, 3])
                {
                }
                column(SalesApprovalRoute_17_2_; SalesApprovalRoute[17, 2])
                {
                }
                column(SalesApprovalRoute_17_1_; SalesApprovalRoute[17, 1])
                {
                }
                column(SalesApprovalRoute_18_6_; SalesApprovalRoute[18, 6])
                {
                }
                column(SalesApprovalRoute_18_5_; SalesApprovalRoute[18, 5])
                {
                }
                column(SalesApprovalRoute_18_7_; SalesApprovalRoute[18, 7])
                {
                }
                column(SalesApprovalRoute_18_4_; SalesApprovalRoute[18, 4])
                {
                }
                column(SalesApprovalRoute_18_3_; SalesApprovalRoute[18, 3])
                {
                }
                column(SalesApprovalRoute_18_2_; SalesApprovalRoute[18, 2])
                {
                }
                column(SalesApprovalRoute_18_1_; SalesApprovalRoute[18, 1])
                {
                }
                column(SalesApprovalRoute_19_6_; SalesApprovalRoute[19, 6])
                {
                }
                column(SalesApprovalRoute_19_5_; SalesApprovalRoute[19, 5])
                {
                }
                column(SalesApprovalRoute_19_7_; SalesApprovalRoute[19, 7])
                {
                }
                column(SalesApprovalRoute_19_4_; SalesApprovalRoute[19, 4])
                {
                }
                column(SalesApprovalRoute_19_3_; SalesApprovalRoute[19, 3])
                {
                }
                column(SalesApprovalRoute_19_2_; SalesApprovalRoute[19, 2])
                {
                }
                column(SalesApprovalRoute_19_1_; SalesApprovalRoute[19, 1])
                {
                }
                column(SalesApprovalRoute_20_6_; SalesApprovalRoute[20, 6])
                {
                }
                column(SalesApprovalRoute_20_5_; SalesApprovalRoute[20, 5])
                {
                }
                column(SalesApprovalRoute_20_7_; SalesApprovalRoute[20, 7])
                {
                }
                column(SalesApprovalRoute_20_4_; SalesApprovalRoute[20, 4])
                {
                }
                column(SalesApprovalRoute_20_3_; SalesApprovalRoute[20, 3])
                {
                }
                column(SalesApprovalRoute_20_2_; SalesApprovalRoute[20, 2])
                {
                }
                column(SalesApprovalRoute_20_1_; SalesApprovalRoute[20, 1])
                {
                }
                column(MakeStatusText_Text008_; MakeStatusText(Text008))
                {
                }
                column(Sales_Approval_User_ID; "User ID")
                {
                }
                column(User_IDCaption; User_IDCaptionLbl)
                {
                }
                column(Approver_IDCaption; Approver_IDCaptionLbl)
                {
                }
                column(Salesamount_LimitCaption; Salesamount_LimitCaptionLbl)
                {
                }
                column(Unlimited_Sales_ApprovalCaption; Unlimited_Sales_ApprovalCaptionLbl)
                {
                }
                column(StatusCaption; StatusCaptionLbl)
                {
                }
                column(MessageCaption; MessageCaptionLbl)
                {
                }
                column(SequenceCaption; SequenceCaptionLbl)
                {
                }
                column(Test_Setup___Sales_Approval_LimitsCaption; Test_Setup___Sales_Approval_LimitsCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    UserSetup: Record "User Setup";
                    SalesApprovalAmount: Integer;
                    ErrorMessage: Text[200];
                begin
                    Clear(SalesApprovalRoute);
                    OK := false;
                    Status := Text001;
                    Stop := false;
                    Brk := false;
                    SalesApprovalAmount := 0;
                    I := 1;
                    TestField("Approver ID");
                    SalesApprovalRoute[I, 1] := "User ID";
                    SalesApprovalRoute[I, 2] := "Approver ID";
                    SalesApprovalRoute[I, 3] := Format("Sales Amount Approval Limit");
                    SalesApprovalRoute[I, 4] := Format("Unlimited Sales Approval");
                    SalesApprovalRoute[I, 5] := ErrorMessage;
                    SalesApprovalRoute[I, 6] := Format(I);
                    SalesApprovalRoute[I, 7] := Status;
                    SalesApprovalAmount := "Sales Amount Approval Limit";
                    Clear(ErrorMessage);

                    TempUserSetup := "Sales Approval";
                    TempUserSetup.Insert();

                    SalesApprovalAmount := "Sales Amount Approval Limit";
                    if "Unlimited Sales Approval" then begin
                        Brk := true;
                        ErrorMessage := Text012;
                        Status := Text001;
                        OK := true;
                        Clear(ErrorMessage);
                    end;
                    if not Brk then begin
                        UserSetup.SetRange("User ID", "Approver ID");
                        if UserSetup.FindFirst() then
                            repeat
                                TempUserSetup := UserSetup;
                                if not TempUserSetup.Insert() then begin
                                    ErrorMessage := StrSubstNo(Text007, UserSetup."User ID", Text013);
                                    Status := Text002;
                                    Brk := true;
                                end;

                                I := I + 1;
                                if UserSetup."User ID" = '' then
                                    UserSetup."User ID" := Text014;
                                if UserSetup."Unlimited Sales Approval" then begin
                                    Brk := true;
                                    ErrorMessage := Text012;
                                    OK := true;
                                    Status := Text001;
                                end;
                                if (UserSetup."Sales Amount Approval Limit" < SalesApprovalAmount) and not
                                   UserSetup."Unlimited Sales Approval"
                                then begin
                                    ErrorMessage := StrSubstNo(Text006, UserSetup.FieldCaption("Sales Amount Approval Limit"));
                                    Status := Text002;
                                    Brk := true;
                                    Stop := true;
                                end;
                                SalesApprovalRoute[I, 1] := UserSetup."User ID";
                                SalesApprovalRoute[I, 2] := UserSetup."Approver ID";
                                SalesApprovalRoute[I, 3] := Format(UserSetup."Sales Amount Approval Limit");
                                SalesApprovalRoute[I, 4] := Format(UserSetup."Unlimited Sales Approval");
                                SalesApprovalRoute[I, 5] := ErrorMessage;
                                SalesApprovalRoute[I, 6] := Format(I);
                                SalesApprovalRoute[I, 7] := Status;
                                SalesApprovalAmount := UserSetup."Sales Amount Approval Limit";
                                if UserSetup."Unlimited Sales Approval" then begin
                                    OK := true;
                                    Brk := true;
                                end;

                                if not Brk then begin
                                    UserSetup.SetRange("User ID", UserSetup."Approver ID");
                                    if UserSetup.FindFirst() then
                                        UserSetup.SetRange("User ID", UserSetup."Approver ID");
                                end;
                                if I = 500 then
                                    Brk := true;
                            until Brk;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if UserCode = '' then
                        Error(Text005);
                    if WhatToTest <> WhatToTest::All then
                        if WhatToTest <> WhatToTest::Sales then
                            CurrReport.Break();
                    SetRange("User ID", UserCode);

                    TempUserSetup.DeleteAll();
                end;
            }
            dataitem("Purchase Approval"; "User Setup")
            {
                DataItemTableView = sorting("User ID");
                column(SalesApprovalRoute_1_6__Control173; SalesApprovalRoute[1, 6])
                {
                }
                column(SalesApprovalRoute_1_5__Control175; SalesApprovalRoute[1, 5])
                {
                }
                column(SalesApprovalRoute_1_7__Control176; SalesApprovalRoute[1, 7])
                {
                }
                column(SalesApprovalRoute_1_4__Control177; SalesApprovalRoute[1, 4])
                {
                }
                column(SalesApprovalRoute_1_3__Control178; SalesApprovalRoute[1, 3])
                {
                }
                column(SalesApprovalRoute_1_2__Control179; SalesApprovalRoute[1, 2])
                {
                }
                column(SalesApprovalRoute_1_1__Control180; SalesApprovalRoute[1, 1])
                {
                }
                column(SalesApprovalRoute_2_6__Control181; SalesApprovalRoute[2, 6])
                {
                }
                column(SalesApprovalRoute_2_5__Control182; SalesApprovalRoute[2, 5])
                {
                }
                column(SalesApprovalRoute_2_7__Control183; SalesApprovalRoute[2, 7])
                {
                }
                column(SalesApprovalRoute_2_4__Control189; SalesApprovalRoute[2, 4])
                {
                }
                column(SalesApprovalRoute_2_3__Control190; SalesApprovalRoute[2, 3])
                {
                }
                column(SalesApprovalRoute_2_2__Control191; SalesApprovalRoute[2, 2])
                {
                }
                column(SalesApprovalRoute_2_1__Control192; SalesApprovalRoute[2, 1])
                {
                }
                column(SalesApprovalRoute_3_6__Control193; SalesApprovalRoute[3, 6])
                {
                }
                column(SalesApprovalRoute_3_5__Control194; SalesApprovalRoute[3, 5])
                {
                }
                column(SalesApprovalRoute_3_7__Control195; SalesApprovalRoute[3, 7])
                {
                }
                column(SalesApprovalRoute_3_4__Control196; SalesApprovalRoute[3, 4])
                {
                }
                column(SalesApprovalRoute_3_3__Control197; SalesApprovalRoute[3, 3])
                {
                }
                column(SalesApprovalRoute_3_2__Control198; SalesApprovalRoute[3, 2])
                {
                }
                column(SalesApprovalRoute_3_1__Control199; SalesApprovalRoute[3, 1])
                {
                }
                column(SalesApprovalRoute_4_6__Control200; SalesApprovalRoute[4, 6])
                {
                }
                column(SalesApprovalRoute_4_5__Control201; SalesApprovalRoute[4, 5])
                {
                }
                column(SalesApprovalRoute_4_7__Control202; SalesApprovalRoute[4, 7])
                {
                }
                column(SalesApprovalRoute_4_4__Control203; SalesApprovalRoute[4, 4])
                {
                }
                column(SalesApprovalRoute_4_3__Control204; SalesApprovalRoute[4, 3])
                {
                }
                column(SalesApprovalRoute_4_2__Control205; SalesApprovalRoute[4, 2])
                {
                }
                column(SalesApprovalRoute_4_1__Control206; SalesApprovalRoute[4, 1])
                {
                }
                column(SalesApprovalRoute_5_6__Control207; SalesApprovalRoute[5, 6])
                {
                }
                column(SalesApprovalRoute_5_5__Control208; SalesApprovalRoute[5, 5])
                {
                }
                column(SalesApprovalRoute_5_7__Control209; SalesApprovalRoute[5, 7])
                {
                }
                column(SalesApprovalRoute_5_4__Control210; SalesApprovalRoute[5, 4])
                {
                }
                column(SalesApprovalRoute_5_3__Control211; SalesApprovalRoute[5, 3])
                {
                }
                column(SalesApprovalRoute_5_2__Control212; SalesApprovalRoute[5, 2])
                {
                }
                column(SalesApprovalRoute_5_1__Control213; SalesApprovalRoute[5, 1])
                {
                }
                column(SalesApprovalRoute_6_6__Control214; SalesApprovalRoute[6, 6])
                {
                }
                column(SalesApprovalRoute_6_5__Control215; SalesApprovalRoute[6, 5])
                {
                }
                column(SalesApprovalRoute_6_7__Control216; SalesApprovalRoute[6, 7])
                {
                }
                column(SalesApprovalRoute_6_4__Control217; SalesApprovalRoute[6, 4])
                {
                }
                column(SalesApprovalRoute_6_3__Control218; SalesApprovalRoute[6, 3])
                {
                }
                column(SalesApprovalRoute_6_2__Control219; SalesApprovalRoute[6, 2])
                {
                }
                column(SalesApprovalRoute_6_1__Control220; SalesApprovalRoute[6, 1])
                {
                }
                column(SalesApprovalRoute_7_6__Control221; SalesApprovalRoute[7, 6])
                {
                }
                column(SalesApprovalRoute_7_5__Control222; SalesApprovalRoute[7, 5])
                {
                }
                column(SalesApprovalRoute_7_7__Control223; SalesApprovalRoute[7, 7])
                {
                }
                column(SalesApprovalRoute_7_4__Control224; SalesApprovalRoute[7, 4])
                {
                }
                column(SalesApprovalRoute_7_3__Control225; SalesApprovalRoute[7, 3])
                {
                }
                column(SalesApprovalRoute_7_2__Control226; SalesApprovalRoute[7, 2])
                {
                }
                column(SalesApprovalRoute_7_1__Control227; SalesApprovalRoute[7, 1])
                {
                }
                column(SalesApprovalRoute_8_6__Control228; SalesApprovalRoute[8, 6])
                {
                }
                column(SalesApprovalRoute_8_5__Control229; SalesApprovalRoute[8, 5])
                {
                }
                column(SalesApprovalRoute_8_7__Control230; SalesApprovalRoute[8, 7])
                {
                }
                column(SalesApprovalRoute_8_4__Control231; SalesApprovalRoute[8, 4])
                {
                }
                column(SalesApprovalRoute_8_3__Control232; SalesApprovalRoute[8, 3])
                {
                }
                column(SalesApprovalRoute_8_2__Control233; SalesApprovalRoute[8, 2])
                {
                }
                column(SalesApprovalRoute_8_1__Control234; SalesApprovalRoute[8, 1])
                {
                }
                column(SalesApprovalRoute_9_6__Control235; SalesApprovalRoute[9, 6])
                {
                }
                column(SalesApprovalRoute_9_5__Control236; SalesApprovalRoute[9, 5])
                {
                }
                column(SalesApprovalRoute_9_7__Control237; SalesApprovalRoute[9, 7])
                {
                }
                column(SalesApprovalRoute_9_4__Control238; SalesApprovalRoute[9, 4])
                {
                }
                column(SalesApprovalRoute_9_3__Control239; SalesApprovalRoute[9, 3])
                {
                }
                column(SalesApprovalRoute_9_2__Control240; SalesApprovalRoute[9, 2])
                {
                }
                column(SalesApprovalRoute_9_1__Control241; SalesApprovalRoute[9, 1])
                {
                }
                column(SalesApprovalRoute_10_6__Control242; SalesApprovalRoute[10, 6])
                {
                }
                column(SalesApprovalRoute_10_5__Control243; SalesApprovalRoute[10, 5])
                {
                }
                column(SalesApprovalRoute_10_7__Control244; SalesApprovalRoute[10, 7])
                {
                }
                column(SalesApprovalRoute_10_4__Control245; SalesApprovalRoute[10, 4])
                {
                }
                column(SalesApprovalRoute_10_3__Control246; SalesApprovalRoute[10, 3])
                {
                }
                column(SalesApprovalRoute_10_2__Control247; SalesApprovalRoute[10, 2])
                {
                }
                column(SalesApprovalRoute_10_1__Control248; SalesApprovalRoute[10, 1])
                {
                }
                column(SalesApprovalRoute_11_6__Control249; SalesApprovalRoute[11, 6])
                {
                }
                column(SalesApprovalRoute_11_5__Control250; SalesApprovalRoute[11, 5])
                {
                }
                column(SalesApprovalRoute_11_7__Control251; SalesApprovalRoute[11, 7])
                {
                }
                column(SalesApprovalRoute_11_4__Control252; SalesApprovalRoute[11, 4])
                {
                }
                column(SalesApprovalRoute_11_3__Control253; SalesApprovalRoute[11, 3])
                {
                }
                column(SalesApprovalRoute_11_2__Control254; SalesApprovalRoute[11, 2])
                {
                }
                column(SalesApprovalRoute_11_1__Control255; SalesApprovalRoute[11, 1])
                {
                }
                column(SalesApprovalRoute_12_6__Control256; SalesApprovalRoute[12, 6])
                {
                }
                column(SalesApprovalRoute_12_5__Control257; SalesApprovalRoute[12, 5])
                {
                }
                column(SalesApprovalRoute_12_7__Control258; SalesApprovalRoute[12, 7])
                {
                }
                column(SalesApprovalRoute_12_4__Control259; SalesApprovalRoute[12, 4])
                {
                }
                column(SalesApprovalRoute_12_3__Control260; SalesApprovalRoute[12, 3])
                {
                }
                column(SalesApprovalRoute_12_2__Control261; SalesApprovalRoute[12, 2])
                {
                }
                column(SalesApprovalRoute_12_1__Control262; SalesApprovalRoute[12, 1])
                {
                }
                column(SalesApprovalRoute_13_6__Control263; SalesApprovalRoute[13, 6])
                {
                }
                column(SalesApprovalRoute_13_5__Control264; SalesApprovalRoute[13, 5])
                {
                }
                column(SalesApprovalRoute_13_7__Control265; SalesApprovalRoute[13, 7])
                {
                }
                column(SalesApprovalRoute_13_4__Control266; SalesApprovalRoute[13, 4])
                {
                }
                column(SalesApprovalRoute_13_3__Control267; SalesApprovalRoute[13, 3])
                {
                }
                column(SalesApprovalRoute_13_2__Control268; SalesApprovalRoute[13, 2])
                {
                }
                column(SalesApprovalRoute_13_1__Control269; SalesApprovalRoute[13, 1])
                {
                }
                column(SalesApprovalRoute_14_6__Control270; SalesApprovalRoute[14, 6])
                {
                }
                column(SalesApprovalRoute_14_5__Control271; SalesApprovalRoute[14, 5])
                {
                }
                column(SalesApprovalRoute_14_7__Control272; SalesApprovalRoute[14, 7])
                {
                }
                column(SalesApprovalRoute_14_4__Control273; SalesApprovalRoute[14, 4])
                {
                }
                column(SalesApprovalRoute_14_3__Control274; SalesApprovalRoute[14, 3])
                {
                }
                column(SalesApprovalRoute_14_2__Control275; SalesApprovalRoute[14, 2])
                {
                }
                column(SalesApprovalRoute_14_1__Control276; SalesApprovalRoute[14, 1])
                {
                }
                column(SalesApprovalRoute_15_6__Control277; SalesApprovalRoute[15, 6])
                {
                }
                column(SalesApprovalRoute_15_5__Control278; SalesApprovalRoute[15, 5])
                {
                }
                column(SalesApprovalRoute_15_7__Control279; SalesApprovalRoute[15, 7])
                {
                }
                column(SalesApprovalRoute_15_4__Control280; SalesApprovalRoute[15, 4])
                {
                }
                column(SalesApprovalRoute_15_3__Control281; SalesApprovalRoute[15, 3])
                {
                }
                column(SalesApprovalRoute_15_2__Control282; SalesApprovalRoute[15, 2])
                {
                }
                column(SalesApprovalRoute_15_1__Control283; SalesApprovalRoute[15, 1])
                {
                }
                column(SalesApprovalRoute_16_6__Control284; SalesApprovalRoute[16, 6])
                {
                }
                column(SalesApprovalRoute_16_5__Control285; SalesApprovalRoute[16, 5])
                {
                }
                column(SalesApprovalRoute_16_7__Control286; SalesApprovalRoute[16, 7])
                {
                }
                column(SalesApprovalRoute_16_4__Control287; SalesApprovalRoute[16, 4])
                {
                }
                column(SalesApprovalRoute_16_3__Control288; SalesApprovalRoute[16, 3])
                {
                }
                column(SalesApprovalRoute_16_2__Control289; SalesApprovalRoute[16, 2])
                {
                }
                column(SalesApprovalRoute_16_1__Control290; SalesApprovalRoute[16, 1])
                {
                }
                column(SalesApprovalRoute_17_6__Control291; SalesApprovalRoute[17, 6])
                {
                }
                column(SalesApprovalRoute_17_5__Control292; SalesApprovalRoute[17, 5])
                {
                }
                column(SalesApprovalRoute_17_7__Control293; SalesApprovalRoute[17, 7])
                {
                }
                column(SalesApprovalRoute_17_4__Control294; SalesApprovalRoute[17, 4])
                {
                }
                column(SalesApprovalRoute_17_3__Control295; SalesApprovalRoute[17, 3])
                {
                }
                column(SalesApprovalRoute_17_2__Control296; SalesApprovalRoute[17, 2])
                {
                }
                column(SalesApprovalRoute_17_1__Control297; SalesApprovalRoute[17, 1])
                {
                }
                column(SalesApprovalRoute_18_6__Control298; SalesApprovalRoute[18, 6])
                {
                }
                column(SalesApprovalRoute_18_5__Control299; SalesApprovalRoute[18, 5])
                {
                }
                column(SalesApprovalRoute_18_7__Control300; SalesApprovalRoute[18, 7])
                {
                }
                column(SalesApprovalRoute_18_4__Control301; SalesApprovalRoute[18, 4])
                {
                }
                column(SalesApprovalRoute_18_3__Control302; SalesApprovalRoute[18, 3])
                {
                }
                column(SalesApprovalRoute_18_2__Control303; SalesApprovalRoute[18, 2])
                {
                }
                column(SalesApprovalRoute_18_1__Control304; SalesApprovalRoute[18, 1])
                {
                }
                column(SalesApprovalRoute_19_6__Control305; SalesApprovalRoute[19, 6])
                {
                }
                column(SalesApprovalRoute_19_5__Control306; SalesApprovalRoute[19, 5])
                {
                }
                column(SalesApprovalRoute_19_7__Control307; SalesApprovalRoute[19, 7])
                {
                }
                column(SalesApprovalRoute_19_4__Control308; SalesApprovalRoute[19, 4])
                {
                }
                column(SalesApprovalRoute_19_3__Control309; SalesApprovalRoute[19, 3])
                {
                }
                column(SalesApprovalRoute_19_2__Control310; SalesApprovalRoute[19, 2])
                {
                }
                column(SalesApprovalRoute_19_1__Control311; SalesApprovalRoute[19, 1])
                {
                }
                column(SalesApprovalRoute_20_6__Control312; SalesApprovalRoute[20, 6])
                {
                }
                column(SalesApprovalRoute_20_5__Control313; SalesApprovalRoute[20, 5])
                {
                }
                column(SalesApprovalRoute_20_7__Control314; SalesApprovalRoute[20, 7])
                {
                }
                column(SalesApprovalRoute_20_4__Control315; SalesApprovalRoute[20, 4])
                {
                }
                column(SalesApprovalRoute_20_3__Control316; SalesApprovalRoute[20, 3])
                {
                }
                column(SalesApprovalRoute_20_2__Control317; SalesApprovalRoute[20, 2])
                {
                }
                column(SalesApprovalRoute_20_1__Control318; SalesApprovalRoute[20, 1])
                {
                }
                column(MakeStatusText_Text009_; MakeStatusText(Text009))
                {
                }
                column(Purchase_Approval_User_ID; "User ID")
                {
                }
                column(Test_Setup___Purchase_Approval_LimitsCaption; Test_Setup___Purchase_Approval_LimitsCaptionLbl)
                {
                }
                column(SequenceCaption_Control9; SequenceCaption_Control9Lbl)
                {
                }
                column(MessageCaption_Control10; MessageCaption_Control10Lbl)
                {
                }
                column(StatusCaption_Control159; StatusCaption_Control159Lbl)
                {
                }
                column(Unlimited_Purchase_ApprovalCaption; Unlimited_Purchase_ApprovalCaptionLbl)
                {
                }
                column(Purchaseamount_LimitCaption; Purchaseamount_LimitCaptionLbl)
                {
                }
                column(Approver_IDCaption_Control162; Approver_IDCaption_Control162Lbl)
                {
                }
                column(User_IDCaption_Control163; User_IDCaption_Control163Lbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    UserSetup: Record "User Setup";
                    PurchaseApprovalAmount: Integer;
                    ErrorMessage: Text[200];
                begin
                    Clear(SalesApprovalRoute);
                    OK := false;
                    Status := Text001;
                    Stop := false;
                    Brk := false;

                    PurchaseApprovalAmount := 0;
                    I := 1;
                    TestField("Approver ID");
                    SalesApprovalRoute[I, 1] := "User ID";
                    SalesApprovalRoute[I, 2] := "Approver ID";
                    SalesApprovalRoute[I, 3] := Format("Purchase Amount Approval Limit");
                    SalesApprovalRoute[I, 4] := Format("Unlimited Purchase Approval");
                    SalesApprovalRoute[I, 5] := ErrorMessage;
                    SalesApprovalRoute[I, 6] := Format(I);
                    SalesApprovalRoute[I, 7] := Status;
                    PurchaseApprovalAmount := "Purchase Amount Approval Limit";
                    Clear(ErrorMessage);

                    TempUserSetup := "Purchase Approval";
                    TempUserSetup.Insert();

                    PurchaseApprovalAmount := "Purchase Amount Approval Limit";
                    if "Unlimited Purchase Approval" then begin
                        Brk := true;
                        ErrorMessage := Text012;
                        Status := Text001;
                        OK := true;
                        Clear(ErrorMessage);
                    end;
                    if not Brk then begin
                        UserSetup.SetRange("User ID", "Approver ID");
                        if UserSetup.FindFirst() then
                            repeat
                                TempUserSetup := UserSetup;
                                if not TempUserSetup.Insert() then begin
                                    ErrorMessage := StrSubstNo(Text007, UserSetup."User ID", Text015);
                                    Status := Text002;
                                    Brk := true;
                                end;
                                I := I + 1;
                                if UserSetup."User ID" = '' then
                                    UserSetup."User ID" := Text014;
                                if UserSetup."Unlimited Purchase Approval" then begin
                                    Brk := true;
                                    ErrorMessage := Text012;
                                    OK := true;
                                    Status := Text001;
                                end;
                                if (UserSetup."Purchase Amount Approval Limit" < PurchaseApprovalAmount) and not
                                   UserSetup."Unlimited Purchase Approval"
                                then begin
                                    ErrorMessage := StrSubstNo(Text006, UserSetup.FieldCaption("Unlimited Purchase Approval"));
                                    Status := Text002;
                                    Brk := true;
                                    Stop := true;
                                end;
                                SalesApprovalRoute[I, 1] := UserSetup."User ID";
                                SalesApprovalRoute[I, 2] := UserSetup."Approver ID";
                                SalesApprovalRoute[I, 3] := Format(UserSetup."Purchase Amount Approval Limit");
                                SalesApprovalRoute[I, 4] := Format(UserSetup."Unlimited Purchase Approval");
                                SalesApprovalRoute[I, 5] := ErrorMessage;
                                SalesApprovalRoute[I, 6] := Format(I);
                                SalesApprovalRoute[I, 7] := Status;
                                PurchaseApprovalAmount := UserSetup."Purchase Amount Approval Limit";
                                if UserSetup."Unlimited Purchase Approval" then
                                    Brk := true;

                                if not Brk then begin
                                    UserSetup.SetRange("User ID", UserSetup."Approver ID");
                                    if UserSetup.FindFirst() then
                                        UserSetup.SetRange("User ID", UserSetup."Approver ID");
                                end;
                                if I = 500 then
                                    Brk := true;
                            until Brk;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if UserCode = '' then
                        Error(Text005);
                    if WhatToTest <> WhatToTest::All then
                        if WhatToTest <> WhatToTest::Purchase then
                            CurrReport.Break();

                    SetRange("User ID", UserCode);
                    TempUserSetup.DeleteAll();
                end;
            }
            dataitem("Request Approval"; "User Setup")
            {
                DataItemTableView = sorting("User ID");
                column(SalesApprovalRoute_1_6__Control319; SalesApprovalRoute[1, 6])
                {
                }
                column(SalesApprovalRoute_1_5__Control320; SalesApprovalRoute[1, 5])
                {
                }
                column(SalesApprovalRoute_1_7__Control321; SalesApprovalRoute[1, 7])
                {
                }
                column(SalesApprovalRoute_1_4__Control322; SalesApprovalRoute[1, 4])
                {
                }
                column(SalesApprovalRoute_1_3__Control323; SalesApprovalRoute[1, 3])
                {
                }
                column(SalesApprovalRoute_1_2__Control324; SalesApprovalRoute[1, 2])
                {
                }
                column(SalesApprovalRoute_1_1__Control325; SalesApprovalRoute[1, 1])
                {
                }
                column(SalesApprovalRoute_2_6__Control326; SalesApprovalRoute[2, 6])
                {
                }
                column(SalesApprovalRoute_2_5__Control327; SalesApprovalRoute[2, 5])
                {
                }
                column(SalesApprovalRoute_2_7__Control328; SalesApprovalRoute[2, 7])
                {
                }
                column(SalesApprovalRoute_2_4__Control329; SalesApprovalRoute[2, 4])
                {
                }
                column(SalesApprovalRoute_2_3__Control330; SalesApprovalRoute[2, 3])
                {
                }
                column(SalesApprovalRoute_2_2__Control331; SalesApprovalRoute[2, 2])
                {
                }
                column(SalesApprovalRoute_2_1__Control332; SalesApprovalRoute[2, 1])
                {
                }
                column(SalesApprovalRoute_3_6__Control333; SalesApprovalRoute[3, 6])
                {
                }
                column(SalesApprovalRoute_3_5__Control334; SalesApprovalRoute[3, 5])
                {
                }
                column(SalesApprovalRoute_3_7__Control335; SalesApprovalRoute[3, 7])
                {
                }
                column(SalesApprovalRoute_3_4__Control336; SalesApprovalRoute[3, 4])
                {
                }
                column(SalesApprovalRoute_3_3__Control337; SalesApprovalRoute[3, 3])
                {
                }
                column(SalesApprovalRoute_3_2__Control338; SalesApprovalRoute[3, 2])
                {
                }
                column(SalesApprovalRoute_3_1__Control339; SalesApprovalRoute[3, 1])
                {
                }
                column(SalesApprovalRoute_4_6__Control340; SalesApprovalRoute[4, 6])
                {
                }
                column(SalesApprovalRoute_4_5__Control341; SalesApprovalRoute[4, 5])
                {
                }
                column(SalesApprovalRoute_4_7__Control342; SalesApprovalRoute[4, 7])
                {
                }
                column(SalesApprovalRoute_4_4__Control343; SalesApprovalRoute[4, 4])
                {
                }
                column(SalesApprovalRoute_4_3__Control344; SalesApprovalRoute[4, 3])
                {
                }
                column(SalesApprovalRoute_4_2__Control345; SalesApprovalRoute[4, 2])
                {
                }
                column(SalesApprovalRoute_4_1__Control346; SalesApprovalRoute[4, 1])
                {
                }
                column(SalesApprovalRoute_5_6__Control438; SalesApprovalRoute[5, 6])
                {
                }
                column(SalesApprovalRoute_5_5__Control439; SalesApprovalRoute[5, 5])
                {
                }
                column(SalesApprovalRoute_5_7__Control440; SalesApprovalRoute[5, 7])
                {
                }
                column(SalesApprovalRoute_5_4__Control441; SalesApprovalRoute[5, 4])
                {
                }
                column(SalesApprovalRoute_5_3__Control442; SalesApprovalRoute[5, 3])
                {
                }
                column(SalesApprovalRoute_5_2__Control443; SalesApprovalRoute[5, 2])
                {
                }
                column(SalesApprovalRoute_5_1__Control444; SalesApprovalRoute[5, 1])
                {
                }
                column(SalesApprovalRoute_6_6__Control347; SalesApprovalRoute[6, 6])
                {
                }
                column(SalesApprovalRoute_6_5__Control348; SalesApprovalRoute[6, 5])
                {
                }
                column(SalesApprovalRoute_6_7__Control349; SalesApprovalRoute[6, 7])
                {
                }
                column(SalesApprovalRoute_6_4__Control350; SalesApprovalRoute[6, 4])
                {
                }
                column(SalesApprovalRoute_6_3__Control351; SalesApprovalRoute[6, 3])
                {
                }
                column(SalesApprovalRoute_6_2__Control352; SalesApprovalRoute[6, 2])
                {
                }
                column(SalesApprovalRoute_6_1__Control353; SalesApprovalRoute[6, 1])
                {
                }
                column(SalesApprovalRoute_7_6__Control354; SalesApprovalRoute[7, 6])
                {
                }
                column(SalesApprovalRoute_7_5__Control355; SalesApprovalRoute[7, 5])
                {
                }
                column(SalesApprovalRoute_7_7__Control356; SalesApprovalRoute[7, 7])
                {
                }
                column(SalesApprovalRoute_7_4__Control357; SalesApprovalRoute[7, 4])
                {
                }
                column(SalesApprovalRoute_7_3__Control358; SalesApprovalRoute[7, 3])
                {
                }
                column(SalesApprovalRoute_7_2__Control359; SalesApprovalRoute[7, 2])
                {
                }
                column(SalesApprovalRoute_7_1__Control360; SalesApprovalRoute[7, 1])
                {
                }
                column(SalesApprovalRoute_8_6__Control361; SalesApprovalRoute[8, 6])
                {
                }
                column(SalesApprovalRoute_8_5__Control362; SalesApprovalRoute[8, 5])
                {
                }
                column(SalesApprovalRoute_8_7__Control363; SalesApprovalRoute[8, 7])
                {
                }
                column(SalesApprovalRoute_8_4__Control364; SalesApprovalRoute[8, 4])
                {
                }
                column(SalesApprovalRoute_8_3__Control365; SalesApprovalRoute[8, 3])
                {
                }
                column(SalesApprovalRoute_8_2__Control366; SalesApprovalRoute[8, 2])
                {
                }
                column(SalesApprovalRoute_8_1__Control367; SalesApprovalRoute[8, 1])
                {
                }
                column(SalesApprovalRoute_9_6__Control368; SalesApprovalRoute[9, 6])
                {
                }
                column(SalesApprovalRoute_9_5__Control369; SalesApprovalRoute[9, 5])
                {
                }
                column(SalesApprovalRoute_9_7__Control370; SalesApprovalRoute[9, 7])
                {
                }
                column(SalesApprovalRoute_9_4__Control371; SalesApprovalRoute[9, 4])
                {
                }
                column(SalesApprovalRoute_9_3__Control372; SalesApprovalRoute[9, 3])
                {
                }
                column(SalesApprovalRoute_9_2__Control373; SalesApprovalRoute[9, 2])
                {
                }
                column(SalesApprovalRoute_9_1__Control374; SalesApprovalRoute[9, 1])
                {
                }
                column(SalesApprovalRoute_10_6__Control375; SalesApprovalRoute[10, 6])
                {
                }
                column(SalesApprovalRoute_10_5__Control376; SalesApprovalRoute[10, 5])
                {
                }
                column(SalesApprovalRoute_10_7__Control377; SalesApprovalRoute[10, 7])
                {
                }
                column(SalesApprovalRoute_10_4__Control378; SalesApprovalRoute[10, 4])
                {
                }
                column(SalesApprovalRoute_10_3__Control379; SalesApprovalRoute[10, 3])
                {
                }
                column(SalesApprovalRoute_10_2__Control380; SalesApprovalRoute[10, 2])
                {
                }
                column(SalesApprovalRoute_10_1__Control381; SalesApprovalRoute[10, 1])
                {
                }
                column(SalesApprovalRoute_11_6__Control382; SalesApprovalRoute[11, 6])
                {
                }
                column(SalesApprovalRoute_11_5__Control383; SalesApprovalRoute[11, 5])
                {
                }
                column(SalesApprovalRoute_11_7__Control384; SalesApprovalRoute[11, 7])
                {
                }
                column(SalesApprovalRoute_11_4__Control385; SalesApprovalRoute[11, 4])
                {
                }
                column(SalesApprovalRoute_11_3__Control386; SalesApprovalRoute[11, 3])
                {
                }
                column(SalesApprovalRoute_11_2__Control387; SalesApprovalRoute[11, 2])
                {
                }
                column(SalesApprovalRoute_11_1__Control388; SalesApprovalRoute[11, 1])
                {
                }
                column(SalesApprovalRoute_12_6__Control389; SalesApprovalRoute[12, 6])
                {
                }
                column(SalesApprovalRoute_12_5__Control390; SalesApprovalRoute[12, 5])
                {
                }
                column(SalesApprovalRoute_12_7__Control391; SalesApprovalRoute[12, 7])
                {
                }
                column(SalesApprovalRoute_12_4__Control392; SalesApprovalRoute[12, 4])
                {
                }
                column(SalesApprovalRoute_12_3__Control393; SalesApprovalRoute[12, 3])
                {
                }
                column(SalesApprovalRoute_12_2__Control394; SalesApprovalRoute[12, 2])
                {
                }
                column(SalesApprovalRoute_12_1__Control395; SalesApprovalRoute[12, 1])
                {
                }
                column(SalesApprovalRoute_13_6__Control396; SalesApprovalRoute[13, 6])
                {
                }
                column(SalesApprovalRoute_13_5__Control397; SalesApprovalRoute[13, 5])
                {
                }
                column(SalesApprovalRoute_13_7__Control398; SalesApprovalRoute[13, 7])
                {
                }
                column(SalesApprovalRoute_13_4__Control399; SalesApprovalRoute[13, 4])
                {
                }
                column(SalesApprovalRoute_13_3__Control400; SalesApprovalRoute[13, 3])
                {
                }
                column(SalesApprovalRoute_13_2__Control401; SalesApprovalRoute[13, 2])
                {
                }
                column(SalesApprovalRoute_13_1__Control402; SalesApprovalRoute[13, 1])
                {
                }
                column(SalesApprovalRoute_14_6__Control403; SalesApprovalRoute[14, 6])
                {
                }
                column(SalesApprovalRoute_14_5__Control404; SalesApprovalRoute[14, 5])
                {
                }
                column(SalesApprovalRoute_14_7__Control405; SalesApprovalRoute[14, 7])
                {
                }
                column(SalesApprovalRoute_14_4__Control406; SalesApprovalRoute[14, 4])
                {
                }
                column(SalesApprovalRoute_14_3__Control407; SalesApprovalRoute[14, 3])
                {
                }
                column(SalesApprovalRoute_14_2__Control408; SalesApprovalRoute[14, 2])
                {
                }
                column(SalesApprovalRoute_14_1__Control409; SalesApprovalRoute[14, 1])
                {
                }
                column(SalesApprovalRoute_15_6__Control410; SalesApprovalRoute[15, 6])
                {
                }
                column(SalesApprovalRoute_15_5__Control411; SalesApprovalRoute[15, 5])
                {
                }
                column(SalesApprovalRoute_15_7__Control412; SalesApprovalRoute[15, 7])
                {
                }
                column(SalesApprovalRoute_15_4__Control413; SalesApprovalRoute[15, 4])
                {
                }
                column(SalesApprovalRoute_15_3__Control414; SalesApprovalRoute[15, 3])
                {
                }
                column(SalesApprovalRoute_15_2__Control415; SalesApprovalRoute[15, 2])
                {
                }
                column(SalesApprovalRoute_15_1__Control416; SalesApprovalRoute[15, 1])
                {
                }
                column(SalesApprovalRoute_16_6__Control417; SalesApprovalRoute[16, 6])
                {
                }
                column(SalesApprovalRoute_16_5__Control418; SalesApprovalRoute[16, 5])
                {
                }
                column(SalesApprovalRoute_16_7__Control419; SalesApprovalRoute[16, 7])
                {
                }
                column(SalesApprovalRoute_16_4__Control420; SalesApprovalRoute[16, 4])
                {
                }
                column(SalesApprovalRoute_16_3__Control421; SalesApprovalRoute[16, 3])
                {
                }
                column(SalesApprovalRoute_16_2__Control422; SalesApprovalRoute[16, 2])
                {
                }
                column(SalesApprovalRoute_16_1__Control423; SalesApprovalRoute[16, 1])
                {
                }
                column(SalesApprovalRoute_17_6__Control424; SalesApprovalRoute[17, 6])
                {
                }
                column(SalesApprovalRoute_17_5__Control425; SalesApprovalRoute[17, 5])
                {
                }
                column(SalesApprovalRoute_17_7__Control426; SalesApprovalRoute[17, 7])
                {
                }
                column(SalesApprovalRoute_17_4__Control427; SalesApprovalRoute[17, 4])
                {
                }
                column(SalesApprovalRoute_17_3__Control428; SalesApprovalRoute[17, 3])
                {
                }
                column(SalesApprovalRoute_17_2__Control429; SalesApprovalRoute[17, 2])
                {
                }
                column(SalesApprovalRoute_17_1__Control430; SalesApprovalRoute[17, 1])
                {
                }
                column(SalesApprovalRoute_18_6__Control431; SalesApprovalRoute[18, 6])
                {
                }
                column(SalesApprovalRoute_18_5__Control432; SalesApprovalRoute[18, 5])
                {
                }
                column(SalesApprovalRoute_18_7__Control433; SalesApprovalRoute[18, 7])
                {
                }
                column(SalesApprovalRoute_18_4__Control434; SalesApprovalRoute[18, 4])
                {
                }
                column(SalesApprovalRoute_18_3__Control435; SalesApprovalRoute[18, 3])
                {
                }
                column(SalesApprovalRoute_18_2__Control436; SalesApprovalRoute[18, 2])
                {
                }
                column(SalesApprovalRoute_18_1__Control437; SalesApprovalRoute[18, 1])
                {
                }
                column(SalesApprovalRoute_19_6__Control445; SalesApprovalRoute[19, 6])
                {
                }
                column(SalesApprovalRoute_19_5__Control446; SalesApprovalRoute[19, 5])
                {
                }
                column(SalesApprovalRoute_19_7__Control447; SalesApprovalRoute[19, 7])
                {
                }
                column(SalesApprovalRoute_19_4__Control448; SalesApprovalRoute[19, 4])
                {
                }
                column(SalesApprovalRoute_19_3__Control449; SalesApprovalRoute[19, 3])
                {
                }
                column(SalesApprovalRoute_19_2__Control450; SalesApprovalRoute[19, 2])
                {
                }
                column(SalesApprovalRoute_19_1__Control451; SalesApprovalRoute[19, 1])
                {
                }
                column(SalesApprovalRoute_20_6__Control452; SalesApprovalRoute[20, 6])
                {
                }
                column(SalesApprovalRoute_20_5__Control453; SalesApprovalRoute[20, 5])
                {
                }
                column(SalesApprovalRoute_20_7__Control454; SalesApprovalRoute[20, 7])
                {
                }
                column(SalesApprovalRoute_20_4__Control455; SalesApprovalRoute[20, 4])
                {
                }
                column(SalesApprovalRoute_20_3__Control456; SalesApprovalRoute[20, 3])
                {
                }
                column(SalesApprovalRoute_20_2__Control457; SalesApprovalRoute[20, 2])
                {
                }
                column(SalesApprovalRoute_20_1__Control458; SalesApprovalRoute[20, 1])
                {
                }
                column(MakeStatusText_Text010_; MakeStatusText(Text010))
                {
                }
                column(Request_Approval_User_ID; "User ID")
                {
                }
                column(Test_Setup___Request_Approval_LimitsCaption; Test_Setup___Request_Approval_LimitsCaptionLbl)
                {
                }
                column(SequenceCaption_Control164; SequenceCaption_Control164Lbl)
                {
                }
                column(MessageCaption_Control165; MessageCaption_Control165Lbl)
                {
                }
                column(StatusCaption_Control167; StatusCaption_Control167Lbl)
                {
                }
                column(Unlimited_Request_ApprovalCaption; Unlimited_Request_ApprovalCaptionLbl)
                {
                }
                column(Requestamount_LimitCaption; Requestamount_LimitCaptionLbl)
                {
                }
                column(Approver_IDCaption_Control170; Approver_IDCaption_Control170Lbl)
                {
                }
                column(User_IDCaption_Control171; User_IDCaption_Control171Lbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    UserSetup: Record "User Setup";
                    RequestApprovalAmount: Integer;
                    ErrorMessage: Text[200];
                begin
                    Clear(SalesApprovalRoute);
                    OK := false;
                    Status := Text001;
                    Stop := false;
                    Brk := false;

                    RequestApprovalAmount := 0;
                    I := 1;
                    TestField("Approver ID");
                    SalesApprovalRoute[I, 1] := "User ID";
                    SalesApprovalRoute[I, 2] := "Approver ID";
                    SalesApprovalRoute[I, 3] := Format("Request Amount Approval Limit");
                    SalesApprovalRoute[I, 4] := Format("Unlimited Request Approval");
                    SalesApprovalRoute[I, 5] := ErrorMessage;
                    SalesApprovalRoute[I, 6] := Format(I);
                    SalesApprovalRoute[I, 7] := Status;
                    RequestApprovalAmount := "Request Amount Approval Limit";
                    Clear(ErrorMessage);

                    TempUserSetup := "Request Approval";
                    TempUserSetup.Insert();

                    RequestApprovalAmount := "Request Amount Approval Limit";
                    if "Unlimited Request Approval" then begin
                        Brk := true;
                        ErrorMessage := Text012;
                        Status := Text001;
                        OK := true;
                        Clear(ErrorMessage);
                    end;
                    if not Brk then begin
                        UserSetup.SetRange("User ID", "Approver ID");
                        if UserSetup.FindFirst() then
                            repeat
                                TempUserSetup := UserSetup;
                                if not TempUserSetup.Insert() then begin
                                    ErrorMessage := StrSubstNo(Text007, UserSetup."User ID", Text016);
                                    Status := Text002;
                                    Brk := true;
                                end;
                                I := I + 1;
                                if UserSetup."User ID" = '' then
                                    UserSetup."User ID" := Text014;
                                if UserSetup."Unlimited Request Approval" then begin
                                    Brk := true;
                                    ErrorMessage := Text012;
                                    Status := Text001;
                                    OK := true;
                                end;
                                if (UserSetup."Request Amount Approval Limit" < RequestApprovalAmount) and not
                                   UserSetup."Unlimited Request Approval"
                                then begin
                                    ErrorMessage := StrSubstNo(Text006, UserSetup.FieldCaption("Unlimited Request Approval"));
                                    Status := Text002;
                                    Brk := true;
                                    Stop := true;
                                end;
                                SalesApprovalRoute[I, 1] := UserSetup."User ID";
                                SalesApprovalRoute[I, 2] := UserSetup."Approver ID";
                                SalesApprovalRoute[I, 3] := Format(UserSetup."Request Amount Approval Limit");
                                SalesApprovalRoute[I, 4] := Format(UserSetup."Unlimited Request Approval");
                                SalesApprovalRoute[I, 5] := ErrorMessage;
                                SalesApprovalRoute[I, 6] := Format(I);
                                SalesApprovalRoute[I, 7] := Status;
                                RequestApprovalAmount := UserSetup."Request Amount Approval Limit";
                                if UserSetup."Unlimited Request Approval" then
                                    Brk := true;

                                if not Brk then begin
                                    UserSetup.SetRange("User ID", UserSetup."Approver ID");
                                    if UserSetup.FindFirst() then
                                        UserSetup.SetRange("User ID", UserSetup."Approver ID");
                                end;
                                if I = 500 then
                                    Brk := true;
                            until Brk;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if UserCode = '' then
                        Error(Text005);
                    if WhatToTest <> WhatToTest::All then
                        if WhatToTest <> WhatToTest::Request then
                            CurrReport.Break();
                    SetRange("User ID", UserCode);
                    TempUserSetup.DeleteAll();
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UserCode; UserCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'User ID';
                        TableRelation = "User Setup";
                        ToolTip = 'Specifies the approval user.';
                    }
                    field(WhatToTest; WhatToTest)
                    {
                        ApplicationArea = Suite;
                        Caption = 'What To Test';
                        OptionCaption = 'Sales Approval Setup,Purchase Approval Setup,Request Approval Setup,All';
                        ToolTip = 'Specifies which approval setup is tested by the batch job.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TempUserSetup: Record "User Setup" temporary;
        SalesApprovalRoute: array[500, 7] of Text[200];
        I: Integer;
        Brk: Boolean;
        Status: Text[5];
#pragma warning disable AA0074
        Text001: Label 'OK';
        Text002: Label 'ERROR';
#pragma warning restore AA0074
        Stop: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'There are problems with the %1 Approval Setup. Re-enter Approval Amounts and make sure that at least one user has unlimited approval rights.';
        Text004: Label '%1 Approval Setup appears to be correct.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        UserCode: Code[50];
        WhatToTest: Option Sales,Purchase,Request,All;
#pragma warning disable AA0074
        Text005: Label 'You must choose a User ID. ';
#pragma warning disable AA0470
        Text006: Label 'User has lower %1 than the previous user.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        OK: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text007: Label 'The user %1 is either set up as approver in the %2 route, or he is set up as his own approver.';
#pragma warning restore AA0470
        Text008: Label 'Sales';
        Text009: Label 'Purchase';
        Text010: Label 'Request';
        Text012: Label 'Unlimited approvals.';
        Text013: Label 'Sales Approval';
        Text014: Label 'None';
        Text015: Label 'Purchase Approval';
        Text016: Label 'Request Approval';
#pragma warning restore AA0074
        Test_Approval_SetupCaptionLbl: Label 'Test Approval Setup';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        User_IDCaptionLbl: Label 'User ID';
        Approver_IDCaptionLbl: Label 'Approver ID';
        Salesamount_LimitCaptionLbl: Label 'Sales Amount Limit';
        Unlimited_Sales_ApprovalCaptionLbl: Label 'Unlimited Sales Approval';
        StatusCaptionLbl: Label 'Status';
        MessageCaptionLbl: Label 'Message';
        SequenceCaptionLbl: Label 'Sequence';
        Test_Setup___Sales_Approval_LimitsCaptionLbl: Label 'Test Setup - Sales Approval Limits';
        Test_Setup___Purchase_Approval_LimitsCaptionLbl: Label 'Test Setup - Purchase Approval Limits';
        SequenceCaption_Control9Lbl: Label 'Sequence';
        MessageCaption_Control10Lbl: Label 'Message';
        StatusCaption_Control159Lbl: Label 'Status';
        Unlimited_Purchase_ApprovalCaptionLbl: Label 'Unlimited Purchase Approval';
        Purchaseamount_LimitCaptionLbl: Label 'Purchase Amount Limit';
        Approver_IDCaption_Control162Lbl: Label 'Approver ID';
        User_IDCaption_Control163Lbl: Label 'User ID';
        Test_Setup___Request_Approval_LimitsCaptionLbl: Label 'Test Setup - Request Approval Limits';
        SequenceCaption_Control164Lbl: Label 'Sequence';
        MessageCaption_Control165Lbl: Label 'Message';
        StatusCaption_Control167Lbl: Label 'Status';
        Unlimited_Request_ApprovalCaptionLbl: Label 'Unlimited Request Approval';
        Requestamount_LimitCaptionLbl: Label 'Request Amount Limit';
        Approver_IDCaption_Control170Lbl: Label 'Approver ID';
        User_IDCaption_Control171Lbl: Label 'User ID';

    local procedure MakeStatusText(ApprovalCaption: Text[250]): Text[250]
    begin
        if OK and not Stop then
            exit(StrSubstNo(Text004, ApprovalCaption));

        exit(StrSubstNo(Text003, ApprovalCaption));
    end;
}

