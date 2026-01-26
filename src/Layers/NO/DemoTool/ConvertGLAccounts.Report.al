report 160801 "Convert GL Accounts"
{
    Caption = 'Convert GL Accounts';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(KontoKonv1; "GL Accounts Conversion")
        {
            DataItemTableView = sorting("Original Account No.", "Entry No.");

            trigger OnAfterGetRecord()
            begin
                // Check that no more accounts are converted to same Account NO.
                VinduTeller := VinduTeller + 1;
                Vindu.Update(1, Round(10000 * VinduTeller / VinduAntall, 1));

                TestKonvKonto.SetRange("No.", "No.");
                if TestKonvKonto.Count > 1 then
                    Error(
                      'An Account must be converted to unique Account NO.\%1 Accounts are converted to account nos. %2.',
                      TestKonvKonto.Count, "No.");

                TestField("No.");
            end;

            trigger OnPreDataItem()
            begin
                VinduAntall := Count;
                VinduTeller := 0;
            end;
        }
        dataitem(KontoKonv2; "GL Accounts Conversion")
        {
            DataItemTableView = sorting("Original Account No.", "Entry No.");

            trigger OnAfterGetRecord()
            begin
                // Konvertere til midlertidig kontonr.
                VinduTeller := VinduTeller + 1;
                Vindu.Update(2, "Original Account No.");
                Vindu.Update(3, Round(10000 * VinduTeller / VinduAntall, 1));
                K1 := Finanskonto."No.";

                // Ikke opprette miderltidig nr. på konto som evt. allerede er under behandling:
                if "Account Status" <> "Account Status"::"Not Converted" then
                    CurrReport.Skip();

                case true of
                    "Original Account No." = '':
                        begin
                            // Er det ny konto ("No. = '') så opprettes ikke noe. Ny konto opprettes i neste dataitem.
                            Validate("Account Status", "Account Status"::Prepared);
                            Modify(true);
                        end;
                    "Account Type" = "Account Type"::Posting:
                        begin
                            Finanskonto.Get("Original Account No.");
                            if Finanskonto.Rename("Temp. Account No.") then begin
                                Validate("Account Status", "Account Status"::Prepared);
                                Validate("Account Error", false);
                            end else
                                Validate("Account Error", true);
                            Modify(true);
                            ICAcc.SetRange("Map-to G/L Acc. No.", "Original Account No.");
                            if ICAcc.Find('-') then
                                repeat
                                    ICAcc."Map-to G/L Acc. No." := "Temp. Account No.";
                                    ICAcc.Modify(true);
                                until ICAcc.Next() = 0;
                        end;
                    else begin
                        // Andre kontotyper enn Konto og dem som ikke er nye endrer bare navn. RENAME brukes ikke.
                        Finanskonto.Get("Original Account No.");
                        Finanskonto.Delete();
                        Finanskonto."No." := "Temp. Account No.";
                        Finanskonto.Insert();
                        Validate("Account Status", "Account Status"::Prepared);
                        ICAcc.SetRange("Map-to G/L Acc. No.", "Original Account No.");
                        if ICAcc.Find('-') then
                            repeat
                                ICAcc."Map-to G/L Acc. No." := "Temp. Account No.";
                                ICAcc.Modify(true);
                            until ICAcc.Next() = 0;
                        Modify(true);
                    end;
                end;

                if Lagre then
                    Commit();
                K2 := Finanskonto."No.";
            end;

            trigger OnPreDataItem()
            begin
                VinduAntall := Count;
                VinduTeller := 0;
            end;
        }
        dataitem(KontoKonv3; "GL Accounts Conversion")
        {
            DataItemTableView = sorting("Original Account No.", "Entry No.");

            trigger OnAfterGetRecord()
            begin
                VinduTeller := VinduTeller + 1;
                Vindu.Update(2, "No.");
                Vindu.Update(4, Round(10000 * VinduTeller / VinduAntall, 1));
                K1 := Finanskonto."No.";

                if ("Account Status" <> "Account Status"::Prepared) and
                   ("No." <> '')
                then
                    // Skip account is not prepared. If new account - continue.
                    CurrReport.Skip();

                if "Original Account No." = '' then begin
                    // Ny konto skal opprettes
                    Finanskonto.Init();
                    Finanskonto.Validate("No.", "No.");
                    Validate("Account Status", "Account Status"::Converted);
                    Validate("Account Error", false);
                    OppdatereKonto();
                    Finanskonto.Insert(true);

                end else begin
                    // Kontoen skal konverteres ferdig
                    Finanskonto.Get("Temp. Account No.");
                    if "Account Type" = "Account Type"::Posting then begin
                        if Finanskonto.Rename("No.") then begin
                            Validate("Account Status", "Account Status"::Converted);
                            Validate("Account Error", false);
                            OppdatereKonto();
                            Finanskonto.Modify(true);

                        end else
                            Validate("Account Error", true);
                    end
                    else begin
                        Validate("Account Status", "Account Status"::Converted);
                        Finanskonto.Delete();
                        OppdatereKonto();
                        Finanskonto."No." := "No.";
                        Finanskonto.Insert();
                    end;
                end;
                ICAcc.SetRange("Map-to G/L Acc. No.", "Temp. Account No.");
                if ICAcc.Find('-') then
                    repeat
                        ICAcc."Map-to G/L Acc. No." := "No.";
                        ICAcc.Name := Name;
                        ICAcc.Modify(true);
                    until ICAcc.Next() = 0;

                Modify(true);

                if Lagre then
                    Commit();
                K2 := Finanskonto."No.";
            end;

            trigger OnPreDataItem()
            begin
                VinduAntall := Count;
                VinduTeller := 0;
            end;
        }
        dataitem(KontoKonv4; "GL Accounts Conversion")
        {
            DataItemTableView = sorting("No.");
            dataitem(AV1; "Analysis View")
            {
                DataItemTableView = sorting(Code);

                trigger OnAfterGetRecord()
                begin
                    K1 := "Account Filter";
                    if KonverterCode("Account Filter", KontoKonv4."Original Account No.", KontoKonv4."Temp. Account No.") then
                        Modify()
                    else
                        CurrReport.Skip();
                    K2 := "Account Filter";
                end;
            }
            dataitem(ASL1; "Acc. Schedule Line")
            {
                DataItemTableView = sorting("Schedule Name", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    K1 := Totaling;
                    if KonverterText(Totaling, KontoKonv4."Original Account No.", KontoKonv4."Temp. Account No.") then
                        Modify()
                    else
                        CurrReport.Skip();
                    K2 := Totaling;
                end;
            }
            dataitem(CT1; "Cost Type")
            {

                trigger OnAfterGetRecord()
                begin
                    K1 := "G/L Account Range";
                    if KonverterText("G/L Account Range", KontoKonv4."Original Account No.", KontoKonv4."Temp. Account No.") then
                        Modify()
                    else
                        CurrReport.Skip();
                    K2 := "G/L Account Range";
                end;
            }

            trigger OnAfterGetRecord()
            begin
                VinduTeller := VinduTeller + 1;
                Vindu.Update(2, "No.");
                Vindu.Update(5, Round(10000 * VinduTeller / VinduAntall, 1));

                if "Formula Status" <> "Formula Status"::"Not Converted" then
                    CurrReport.Skip();

                Validate("Formula Status", "Formula Status"::Prepared);
                Modify();

                if "Original Account No." = "No." then
                    CurrReport.Skip();
                if "Original Account No." = '' then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                // Konvertere formler
                VinduAntall := Count;
                VinduTeller := 0;
            end;
        }
        dataitem(KontoKonv5; "GL Accounts Conversion")
        {
            DataItemTableView = sorting("No.");
            dataitem(AV2; "Analysis View")
            {
                DataItemTableView = sorting(Code);

                trigger OnAfterGetRecord()
                begin
                    K1 := "Account Filter";
                    if KonverterCode("Account Filter", KontoKonv5."Temp. Account No.", KontoKonv5."No.") then
                        Modify()
                    else
                        CurrReport.Skip();
                    K2 := "Account Filter";
                end;
            }
            dataitem(ASL2; "Acc. Schedule Line")
            {
                DataItemTableView = sorting("Schedule Name", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    K1 := Totaling;
                    if KonverterText(Totaling, KontoKonv5."Temp. Account No.", KontoKonv5."No.") then
                        Modify()
                    else
                        CurrReport.Skip();
                    K2 := Totaling;
                end;
            }
            dataitem(CT2; "Cost Type")
            {

                trigger OnAfterGetRecord()
                begin
                    K1 := "G/L Account Range";
                    if KonverterText("G/L Account Range", KontoKonv5."Temp. Account No.", KontoKonv5."No.") then
                        Modify()
                    else
                        CurrReport.Skip();
                    K2 := "G/L Account Range";
                end;
            }

            trigger OnAfterGetRecord()
            begin
                VinduTeller := VinduTeller + 1;
                Vindu.Update(2, "No.");
                Vindu.Update(6, Round(10000 * VinduTeller / VinduAntall, 1));

                if "Formula Status" <> "Formula Status"::Prepared then
                    CurrReport.Skip();

                Validate("Formula Status", "Formula Status"::Converted);
                Modify();

                if "Original Account No." = "No." then
                    CurrReport.Skip();
                if "Original Account No." = '' then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                VinduAntall := Count;
                VinduTeller := 0;
            end;
        }
        dataitem(ICGLAcc; "IC G/L Account")
        {

            trigger OnAfterGetRecord()
            begin
                GLAcc.SetCurrentKey("No.");
                GLAcc.SetRange("No.", "Map-to G/L Acc. No.");
                if GLAcc.Find('-') then begin
                    ICGLAcc.Name := GLAcc.Name;
                    Modify(true);
                end;
            end;
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

    labels
    {
    }

    trigger OnPostReport()
    begin
        Vindu.Close();
        if Feil then
            Message(
              'Finished converting GL Accounts\Note: Some accounts could not be converted.' +
              'These are marked with "Yes" in field "Feil".\' +
              'The error must be corrected and the conversion restarted. Missing accounts will then be converted')
        else
            ;
        //  MESSAGE('Finished converting GL Accounts');
    end;

    trigger OnPreReport()
    begin
        Feil := false;
        Vindu.Open(
          'Control                 @1@@@@@@@@@@@@@@@@@@\\' +
          'Converting account      #2########\' +
          'Adjusting for conver.   @3@@@@@@@@@@@@@@@@@@\' +
          'Converting GL Accounts  @4@@@@@@@@@@@@@@@@@@\' +
          'Adjusting formulas      @5@@@@@@@@@@@@@@@@@@\' +
          'Converting formulas     @6@@@@@@@@@@@@@@@@@@');
    end;

    var
        Finanskonto: Record "G/L Account";
        TestKonvKonto: Record "GL Accounts Conversion";
        Vindu: Dialog;
        VinduAntall: Integer;
        VinduTeller: Integer;
        Feil: Boolean;
        Lagre: Boolean;
        Pos: Integer;
        Test: Code[250];
        K1: Code[250];
        K2: Code[250];
        ICAcc: Record "IC G/L Account";
        GLAcc: Record "G/L Account";

    procedure OppdatereKonto()
    begin
        Finanskonto.TransferFields(KontoKonv3);
        if KontoKonv3.Name <> '' then begin
            Finanskonto.Name := KontoKonv3.Name;
            Finanskonto."Search Name" := KontoKonv3."Search Name";
        end;
    end;

    procedure KonverterCode(var Formel: Code[250]; OpprKontonr: Code[20]; NyttKontonr: Code[20]): Boolean
    var
        HuskFormel: Text[250];
    begin
        HuskFormel := Formel;
        Pos := StrPos(Formel, OpprKontonr);
        if StrLen(Formel) > (Pos + StrLen(OpprKontonr) - 1) then
            if Formel[Pos + StrLen(OpprKontonr)] = '0' then
                Pos := 0; // Do not convert temp. account nos.
        if Pos > 0 then begin
            Test := CopyStr(Formel, Pos + StrLen(OpprKontonr));
            Formel :=
              CopyStr(Formel, 1, Pos - 1) + NyttKontonr + CopyStr(Formel, Pos + StrLen(OpprKontonr));
            if StrPos(Test, OpprKontonr) > 0 then // Several occurences of the text. An error rises,
                Error('Account No. "%1" occurs several times in a formula!');
        end;

        exit(HuskFormel <> Formel);
    end;

    procedure KonverterText(var Formel: Text[250]; OpprKontonr: Code[20]; NyttKontonr: Code[20]): Boolean
    var
        SubPos: Integer;
        HuskFormel: Text[250];
    begin
        HuskFormel := Formel;
        Pos := StrPos(Formel, OpprKontonr);
        if StrLen(Formel) > (Pos + StrLen(OpprKontonr) - 1) then
            if Formel[Pos + StrLen(OpprKontonr)] = '0' then
                Pos := 0; // Do not convert temp. Account Nos.
        if Pos > 0 then begin
            Test := CopyStr(Formel, Pos + StrLen(OpprKontonr));
            Formel :=
              CopyStr(Formel, 1, Pos - 1) + NyttKontonr + CopyStr(Formel, Pos + StrLen(OpprKontonr));
            SubPos := StrPos(Test, OpprKontonr);
            if SubPos > 0 then // Several occurences of the text. An error rises,
                if (Test[SubPos - 1] <> ',') and (Test[SubPos - 2] <> ',') then
                    Error('Account No. "%1" occurs several times in a formula!', OpprKontonr);
        end;
        exit(HuskFormel <> Formel);
    end;
}

