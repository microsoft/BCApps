// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
enum 50110 "Report Filename Output Route"
{
    // Values 1-4 are the platform's own intent vocabulary rather than a parallel one. They are
    // read from the report payload's 'intent' by Report Filename Subscribers, which maps PRINT,
    // PREVIEW, SAVE and DOWNLOAD onto them and anything else onto Any.
    //
    // Values 5-10 name the application-side routes, which the platform has no concept of. Their
    // captions are Business Central's own words for the same thing, so an administrator meets
    // nothing new: Attach as PDF is the action on every document page, and Disk and
    // PDF & Electronic Document are the Document Sending Profile's own options.
    //
    //   Email                     Document-Mailing, the emailed copy
    //   AttachAsPdf               Attach as PDF - the copy that lands on the document's Attached
    //                             Documents
    //   Scheduled                 the job queue's Report Inbox entry
    //   Disk                      Send to Disk with the Disk option PDF, online and on-premises
    //   PdfAndElectronicDocument  the PDF zipped together with an electronic document
    //   ElectronicDocument        the electronic document (XML) and the zip it goes into
    //
    // Named Output Route, and not Channel: Business Central has no field called Channel for this,
    // and "delivery" is its word for shipping goods.

    Extensible = true;
    Caption = 'Report Filename Output Route';
    // Public: extensible means an extension adds values, which requires reaching it.
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

    // Send to Disk produces a file for the user to keep, which is nothing like an attachment on a
    // document - so it is its own value rather than sharing Attachment. It runs online as well:
    // Report Selections' SendToDiskForCust and its siblings are Scope = 'OnPrem', which stops a
    // Cloud extension calling them, not Base Application - Document Sending Profile.SendToDisk
    // calls SendToDiskForCust with no on-premises check, and online the file is downloaded
    // (the user did Send, Disk = PDF, in their online sandbox on 7 October).
    value(8; Disk)
    {
        Caption = 'Disk';
    }

    // The PDF inside the zip a Document Sending Profile produces when its E-Mail Attachment or its
    // Disk option is "PDF & Electronic Document". Its own value rather than Email or Save to Disk,
    // because Base Application builds that zip in one function per side - SendToZipForCust and
    // SendToZipForVend - that both routes call, and nothing that reaches the name says which route
    // is running. A value that is always certain was chosen over one inferred from event order.
    // A pattern on Any names it too.
    value(9; PdfAndElectronicDocument)
    {
        Caption = 'PDF & Electronic Document';
    }

    // The electronic document itself - the XML file a Document Sending Profile writes to Disk or
    // attaches to an email when its option is "Electronic Document" or "PDF & Electronic Document" -
    // and the zip it goes into. Named by the file, like the zipped PDF above, and not by the profile
    // option: Electronic Document Format.SendElectronically builds the name for both options, and
    // nothing that reaches it says which option is running. "Electronic Document" is the profile's own
    // word for the file. The electronic document service's files are never renamed.
    value(10; ElectronicDocument)
    {
        Caption = 'Electronic Document';
    }
}
