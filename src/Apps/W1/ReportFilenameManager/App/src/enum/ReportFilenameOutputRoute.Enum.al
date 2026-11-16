// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

enum 8125 "Report Filename Output Route"
{
    // Values 1-4 map the report payload's 'intent' (PRINT, PREVIEW, SAVE, DOWNLOAD); any other
    // intent maps to Any. Values 5-10 are not read from the intent: this app's subscribers set them
    // from the Base Application route that produces the file.

    Extensible = true;
    Caption = 'Report Filename Output Route';
    Access = Public;

    value(0; Any)
    {
        Caption = 'Any';
    }
    value(1; Print)
    {
        Caption = 'Print';
    }
    value(2; Preview)
    {
        Caption = 'Preview';
    }
    value(3; Save)
    {
        Caption = 'Save';
    }
    value(4; Download)
    {
        Caption = 'Download';
    }
    value(5; Email)
    {
        Caption = 'Email';
    }
    value(6; AttachAsPdf)
    {
        Caption = 'Attach as PDF';
    }
    value(7; Scheduled)
    {
        Caption = 'Scheduled';
    }

    // Send to Disk with the Disk option PDF. Also reached online: SendToDiskForCust's
    // Scope('OnPrem') only stops cloud-target extensions calling it; Document Sending
    // Profile.SendToDisk, which has no such scope, calls it.
    value(8; Disk)
    {
        Caption = 'Disk';
    }

    // The PDF zipped with an electronic document. Its own value rather than Email or Disk because
    // SendToZipForCust/SendToZipForVend serve both routes and their events do not say which one called.
    value(9; PdfAndElectronicDocument)
    {
        Caption = 'PDF & Electronic Document';
    }

    // The electronic document (XML) and its zip, for either Document Sending Profile option:
    // SendElectronically builds the name for both. Electronic document service files are never renamed.
    value(10; ElectronicDocument)
    {
        Caption = 'Electronic Document';
    }
}
