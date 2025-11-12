// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Analysis;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.RoleCenters;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.Utilities;
using System.Privacy;

codeunit 1766 "CRM-Data Classification"
{
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", 'OnCreateEvaluationDataOnAfterClassifyTablesToNormal', '', false, false)]
    local procedure OnClassifyTables()
    begin
        ClassifyTables();
    end;

    local procedure ClassifyTables()
    begin
        ClassifyContact();
        ClassifyContactAltAddress();
        ClassifyAttendee();
        ClassifyOfficeContactDetails();
        ClassifyCampaignEntry();
        ClassifyCommunicationMethod();
        ClassifySavedSegmentCriteria();
        ClassifyOpportunityEntry();
        ClassifyOpportunity();
        ClassifyContactProfileAnswer();
        ClassifyTodo();
        ClassifyMarketingSetup();
        ClassifySegmentLine();
        ClassifyLoggedSegment();
        ClassifyInteractionLogEntry();
        ClassifyInteractionMergeData();
        ClassifyMergeDuplicatesBuffer();
        ClassifyMergeDuplicatesConflict();
        ClassifyExchangeSync();
        ClassifySalespersonPurchaser();

        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Office Add-in Context");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Office Add-in Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Office Invoice");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Office Add-in");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Office Admin. Credentials");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Office Job Journal");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Office Document Selection");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Office Suggested Line Item");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Alt. Addr. Date Range");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Business Relation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Business Relation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Mailing Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Mailing Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Industry Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Industry Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Information Buffer");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Web Source");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Web Source");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Rlshp. Mgt. Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Attachment);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Interaction Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Interaction Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Responsibility");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Job Responsibility");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Merge Duplicates Line Buffer");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Salutation);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Salutation Formula");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Organizational Level");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Campaign);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Campaign Status");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Delivery Sorter");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Segment Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Segment History");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Activity);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Activity Step");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Team);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Team Salesperson");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Duplicate");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Dupl. Details Buffer");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Cont. Duplicate Search String");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Profile Questionnaire Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Profile Questionnaire Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Cycle");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Cycle Stage");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Close Opportunity Code");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Duplicate Search String Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Segment Wizard Filter");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Segment Criteria Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Saved Segment Criteria Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Contact Value");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"RM Matrix Management");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Interaction Tmpl. Language");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Segment Interaction Language");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Rating);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Interaction Template Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Current Salesperson");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Exchange Folder");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Exchange Service Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Exchange Contact");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Campaign Target Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"To-do Interaction Language");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Relationship Mgmt. Cue");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Exchange Object");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inter. Log Entry Comment Line");
    end;

    local procedure ClassifyMergeDuplicatesBuffer()
    var
        DummyMergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Merge Duplicates Buffer";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyMergeDuplicatesBuffer.FieldNo("Duplicate Record ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyMergeDuplicatesBuffer.FieldNo("Current Record ID"));
    end;

    local procedure ClassifyMergeDuplicatesConflict()
    var
        DummyMergeDuplicatesConflict: Record "Merge Duplicates Conflict";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Merge Duplicates Conflict";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyMergeDuplicatesConflict.FieldNo(Duplicate));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyMergeDuplicatesConflict.FieldNo(Current));
    end;

    local procedure ClassifyContactAltAddress()
    var
        DummyContactAltAddress: Record "Contact Alt. Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Contact Alt. Address";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Search E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Telex Answer Back"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Home Page"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo(Pager));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Mobile Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Extension No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Telex No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Country/Region Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Company Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContactAltAddress.FieldNo("Company Name"));
    end;

    local procedure ClassifyOfficeContactDetails()
    var
        DummyOfficeContactDetails: Record "Office Contact Details";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Office Contact Details";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOfficeContactDetails.FieldNo("Contact Name"));
    end;

    local procedure ClassifyAttendee()
    var
        DummyAttendee: Record Attendee;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Attendee;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyAttendee.FieldNo("Attendee Name"));
    end;

    local procedure ClassifyCampaignEntry()
    var
        DummyCampaignEntry: Record "Campaign Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Campaign Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Register No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Salesperson Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo(Canceled));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Segment No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCampaignEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo(Date));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Campaign No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCampaignEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyCommunicationMethod()
    var
        DummyCommunicationMethod: Record "Communication Method";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Communication Method";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCommunicationMethod.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCommunicationMethod.FieldNo(Name));
    end;

    local procedure ClassifySavedSegmentCriteria()
    var
        DummySavedSegmentCriteria: Record "Saved Segment Criteria";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Saved Segment Criteria";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySavedSegmentCriteria.FieldNo("User ID"));
    end;

    local procedure ClassifyOpportunityEntry()
    var
        DummyOpportunityEntry: Record "Opportunity Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Opportunity Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Sales Cycle Stage Description"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Action Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Cancel Old To Do"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Wizard Step"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Estimated Close Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Previous Sales Cycle Stage"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Close Opportunity Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Probability %"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Chances of Success %"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Completed %"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Calcd. Current Value (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Estimated Value (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Action Taken"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Days Open"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Date Closed"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo(Active));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Date of Change"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Campaign No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Salesperson Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Contact Company No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Contact No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Sales Cycle Stage"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Sales Cycle Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Opportunity No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyOpportunityEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyOpportunity()
    var
        DummyOpportunity: Record Opportunity;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Opportunity;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOpportunity.FieldNo("Wizard Contact Name"));
    end;

    local procedure ClassifyContactProfileAnswer()
    var
        DummyContactProfileAnswer: Record "Contact Profile Answer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Contact Profile Answer";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyContactProfileAnswer.FieldNo("Profile Questionnaire Value"));
    end;

    local procedure ClassifyTodo()
    var
        DummyToDo: Record "To-do";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"To-do";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyToDo.FieldNo("Wizard Contact Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyToDo.FieldNo("Completed By"));
    end;

    local procedure ClassifyMarketingSetup()
    var
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Marketing Setup";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
    end;

    local procedure ClassifySegmentLine()
    var
        DummySegmentLine: Record "Segment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Segment Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySegmentLine.FieldNo("Wizard Contact Name"));
    end;

    local procedure ClassifyLoggedSegment()
    var
        DummyLoggedSegment: Record "Logged Segment";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Logged Segment";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyLoggedSegment.FieldNo("User ID"));
    end;

    local procedure ClassifyInteractionLogEntry()
    var
        DummyInteractionLogEntry: Record "Interaction Log Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Interaction Log Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Postponed));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Opportunity No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Subject));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("E-Mail Logged"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Interaction Language Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Send Word Docs. as Attmt."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Contact Via"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Doc. No. Occurrence"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Version No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Logged Segment Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Contact Alt. Address Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Correspondence Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Canceled));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Delivery Status"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Salesperson Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("To-do No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Attempt Failed"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Time of Interaction"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Evaluation));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Segment No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Campaign Target"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Campaign Response"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Campaign Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Campaign No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Interaction Template Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Interaction Group Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyInteractionLogEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Duration (Min.)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Cost (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Attachment No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Initiated By"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Information Flow"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo(Date));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Contact Company No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Contact No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionLogEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyInteractionMergeData()
    var
        DummyInteractionMergeData: Record "Interaction Merge Data";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Interaction Merge Data";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInteractionMergeData.FieldNo(ID));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyInteractionMergeData.FieldNo("Contact No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyInteractionMergeData.FieldNo("Salesperson Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyInteractionMergeData.FieldNo("Log Entry Number"));
    end;

    local procedure ClassifyContact()
    var
        DummyContact: Record Contact;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Contact;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("E-Mail 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Search E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo(Image));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo(Pager));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Mobile Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Extension No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo(Surname));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Middle Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("First Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Home Page"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyContact.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Telex Answer Back"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Telex No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo("Search Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyContact.FieldNo(Name));
    end;

    local procedure ClassifyExchangeSync()
    var
        DummyExchangeSync: Record "Exchange Sync";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Exchange Sync";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyExchangeSync.FieldNo("User ID"));
    end;

    local procedure ClassifySalespersonPurchaser()
    var
        DummySalespersonPurchaser: Record "Salesperson/Purchaser";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Salesperson/Purchaser";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummySalespersonPurchaser.FieldNo("Job Title"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo(Image));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo("E-Mail 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo("Search E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalespersonPurchaser.FieldNo(Name));
    end;
}
