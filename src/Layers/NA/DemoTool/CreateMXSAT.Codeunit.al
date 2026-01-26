codeunit 169000 "Create MX SAT"
{

    trigger OnRun()
    var
        FileDirectory: Text;
    begin
        FileDirectory := 'MXCatalogs\';

        InsertBLOBFromFile(FileDirectory, 'SATClassifications.xml');
        InsertBLOBFromFile(FileDirectory, 'SATCountry_Codes.xml');
        InsertBLOBFromFile(FileDirectory, 'SATPayment_Methods.xml');
        InsertBLOBFromFile(FileDirectory, 'SATPayment_Terms.xml');
        InsertBLOBFromFile(FileDirectory, 'SATRelationship_Types.xml');
        InsertBLOBFromFile(FileDirectory, 'SATTax_Schemes.xml');
        InsertBLOBFromFile(FileDirectory, 'SATU_of_M.xml');
        InsertBLOBFromFile(FileDirectory, 'SATUse_Codes.xml');
        InsertBLOBFromFile(FileDirectory, 'CFDICancellationReasons.xml');
        InsertBLOBFromFile(FileDirectory, 'CFDIExportCodes.xml');
        InsertBLOBFromFile(FileDirectory, 'CFDISubjectsToTax.xml');
        InsertBLOBFromFile(FileDirectory, 'SATIncoterms.xml');
        InsertBLOBFromFile(FileDirectory, 'SATCustomUnits.xml');
        InsertBLOBFromFile(FileDirectory, 'SATTransferReasons.xml');

        InsertBLOBFromFile(FileDirectory, 'SATFederalMotorTransport.xml');
        InsertBLOBFromFile(FileDirectory, 'SATTrailerTypes.xml');
        InsertBLOBFromFile(FileDirectory, 'SATPermissionTypes.xml');
        InsertBLOBFromFile(FileDirectory, 'SATHazardousMaterials.xml');
        InsertBLOBFromFile(FileDirectory, 'SATPackagingTypes.xml');
        InsertBLOBFromFile(FileDirectory, 'SATStates.xml');
        InsertBLOBFromFile(FileDirectory, 'SATMunicipalities.xml');
        InsertBLOBFromFile(FileDirectory, 'SATLocalities.xml');
        InsertBLOBFromFile(FileDirectory, 'SATSuburb1.xml');
        InsertBLOBFromFile(FileDirectory, 'SATSuburb2.xml');
        InsertBLOBFromFile(FileDirectory, 'SATSuburb3.xml');
        InsertBLOBFromFile(FileDirectory, 'SATSuburb4.xml');
        InsertBLOBFromFile(FileDirectory, 'SATWeightUnitsOfMeasure.xml');
        InsertBLOBFromFile(FileDirectory, 'SATMaterialTypes.xml');
        InsertBLOBFromFile(FileDirectory, 'SATCustomsRegimes.xml');
        InsertBLOBFromFile(FileDirectory, 'SATCustomsDocuments.xml');
    end;

    local procedure InsertBLOBFromFile(FilePath: Text; FileName: Text): Code[50]
    var
        MediaResources: Record "Media Resources";
        File: File;
        BLOBInStream: InStream;
        BLOBOutStream: OutStream;
        MediaResourceCode: Code[50];
    begin
        MediaResourceCode := CopyStr(FileName, 1, MaxStrLen(MediaResourceCode));
        if MediaResources.Get(MediaResourceCode) then
            exit(MediaResourceCode);

        if not File.Open(FilePath + FileName) then
            exit('');
        File.CreateInStream(BLOBInStream);

        MediaResources.Init();
        MediaResources.Validate(Code, MediaResourceCode);
        MediaResources.Blob.CreateOutStream(BLOBOutStream);
        CopyStream(BLOBOutStream, BLOBInStream);
        File.Close();
        MediaResources.Insert(true);
    end;
}

