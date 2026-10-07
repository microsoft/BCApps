codeunit 118853 "Create Dist. Production"
{

    trigger OnRun()
    begin
        CreateProdBOMHeader.InsertData(
          'LS-100', '', XLoudspeaker100WOakwoodDeluxe, XPCS, 19020101D);
        CreateProdBOMLine.InsertData(
          'LS-100', '', 1, 'LSU-15', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        CreateProdBOMLine.InsertData(
          'LS-100', '', 1, 'LSU-8', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        CreateProdBOMLine.InsertData(
          'LS-100', '', 1, 'LSU-4', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        CreateProdBOMLine.InsertData(
          'LS-100', '', 1, 'FF-100', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        CreateProdBOMLine.InsertData(
          'LS-100', '', 1, 'C-100', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        CreateProdBOMLine.InsertData(
          'LS-100', '', 1, 'HS-100', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        CreateProdBOMLine.InsertData(
          'LS-100', '', 1, 'SPK-100', 0, 0, 0, 0, 0, 4, '', '', '', 0, 0D, 0D);

        UpdateProdBOMHeader.UpdateItems('LS-100', 'LS-100');
        UpdateProdBOMHeader.CloseProdBOM('LS-100', '');
    end;

    var
        CreateProdBOMHeader: Codeunit "Create Prod. BOM Headers";
        CreateProdBOMLine: Codeunit "Create Prod. BOM Lines";
        UpdateProdBOMHeader: Codeunit "Update Prod. BOM Headers";
        XLoudspeaker100WOakwoodDeluxe: Label 'Loudspeaker100W Oakwood Deluxe';
        XPCS: Label 'PCS';
}

