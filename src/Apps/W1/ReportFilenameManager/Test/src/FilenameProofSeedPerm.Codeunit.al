// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50179 "Filename Proof Seed Perm"
{
    // Run by an administrator before Filename Permission Tests runs as an ordinary user. That user
    // may not create a pattern - which is the point - so the pattern it is named by has to exist
    // already. Leaves one enabled pattern, Invoice-[No.] on Standard Sales - Invoice, on Any channel.

    trigger OnRun()
    var
        Pattern: Record "Report Filename Pattern";
        ProofGuard: Codeunit "Filename Proof Guard";
    begin
        ProofGuard.ClearPatterns();

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", PatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    var
        PatternTok: Label 'Invoice-[No.]', Locked = true;
}
