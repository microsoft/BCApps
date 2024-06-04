// TODO: Reuse the multi upload
// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------

// namespace System.TestTools.AITestToolkit;

// table 149031 "BCCT Dataset"
// {
//     DataClassification = CustomerContent;
//     LookupPageId = "BCCT Datasets";
//     DrillDownPageId = "BCCT Dataset";


//     fields
//     {
//         field(1; "Dataset Name"; Text[100])
//         {
//             NotBlank = true;
//             Caption = 'Dataset Name';
//             // ToolTip ='Specifies the name of the dataset.';

//             trigger OnValidate()
//             var
//                 DatasetLine: Record "BCCT Dataset Line";
//                 DatasetNameEmptyErr: Label 'Dataset Name cannot be empty.';
//             begin
//                 if Rec."Dataset Name" = '' then
//                     Error(DatasetNameEmptyErr);
//                 DatasetLine.SetRange("Dataset Name", xRec."Dataset Name"); //TODO: this will not work when renaming a dataset from API because of xRec usage
//                 DatasetLine.SetLoadFields(Id);
//                 if DatasetLine.FindSet(true) then
//                     repeat
//                         DatasetLine.Rename(DatasetLine.Id, Rec."Dataset Name");
//                     until DatasetLine.Next() = 0;
//             end;
//         }
//         field(2; "Line Count"; Integer)
//         {
//             FieldClass = FlowField;
//             CalcFormula = count("BCCT Dataset Line" where("Dataset Name" = field("Dataset Name")));
//         }
//     }

//     keys
//     {
//         key(Key1; "Dataset Name")
//         {
//             Clustered = true;
//         }
//     }

//     fieldgroups
//     {
//         fieldgroup(DropDown; "Dataset Name", "Line Count")
//         {
//         }
//     }

//     trigger OnDelete()
//     var
//         BCCTDatasetLines: Record "BCCT Dataset Line";
//         BCCTHeader: Record "BCCT Header";
//         BCCTLines: Record "BCCT Line";
//         DatasetBeingUsedInHeaderErr: Label 'The dataset is being used in BCCT Header(s). Please remove the dataset from the BCCT Header(s) before deleting it.';
//         DatasetBeingUsedInLineErr: Label 'The dataset is being used in BCCT Line(s). Please remove the dataset from the BCCT Line(s) before deleting it.';
//     begin
//         // Throw an error if the dataset is being used somewhere
//         BCCTHeader.SetRange("Input Dataset", Rec."Dataset Name");
//         if not BCCTHeader.IsEmpty() then
//             Error(DatasetBeingUsedInHeaderErr);

//         BCCTLines.SetRange("Input Dataset", Rec."Dataset Name");
//         if not BCCTLines.IsEmpty() then
//             Error(DatasetBeingUsedInLineErr);

//         BCCTDatasetLines.SetRange("Dataset Name", "Dataset Name");
//         BCCTDatasetLines.DeleteAll();
//     end;

//     internal procedure UploadDataset(var FileDataInStream: InStream; DatasetName: Text[100])
//     var
//         ExistingDatasets: Record "BCCT Dataset";
//         DatasetLine: Record "BCCT Dataset Line";
//         JsonLine: Text;
//         JsonLineObj: JsonObject;
//         Options: Text;
//         Selected: Integer;
//         StrMenuLbl: Label 'Overwrite,Rename and Upload,Exit';
//         DialogTitleLbl: Label 'Dataset with name %1 already exists. Choose one of the following options:', Comment = '%1=Dataset Name';
//     begin
//         ExistingDatasets.SetLoadFields("Dataset Name");
//         ExistingDatasets.SetRange("Dataset Name", DatasetName);
//         if not ExistingDatasets.IsEmpty() then begin
//             // Show menu dialog dialog
//             if GuiAllowed then begin
//                 Options := StrMenuLbl;
//                 Selected := Dialog.StrMenu(Options, 3, StrSubstNo(DialogTitleLbl, DatasetName));
//             end
//             else
//                 Selected := 1; //Overwrite
//             case Selected of
//                 1:
//                     begin
//                         DatasetLine.SetRange("Dataset Name", DatasetName);
//                         DatasetLine.DeleteAll();
//                     end;
//                 2:
//                     begin
//                         DatasetName := DatasetName + ' - ' + CreateGuid();
//                         Rec.Init();
//                         Rec."Dataset Name" := DatasetName;
//                         Rec.Insert();
//                     end;
//                 3:
//                     exit;
//             end;
//         end
//         else begin
//             Rec.Init();
//             Rec."Dataset Name" := DatasetName;
//             Rec.Insert();
//         end;

//         while FileDataInStream.ReadText(JsonLine) > 0 do begin
//             DatasetLine.Init();
//             DatasetLine.Id := 0;
//             DatasetLine."Dataset Name" := DatasetName;
//             JsonLineObj.ReadFrom(JsonLine.Trim()); //Validate the JSON line
//             DatasetLine.SetInputTextAsBlob(JsonLine.Trim());
//             DatasetLine.Insert();
//         end
//     end;

// }