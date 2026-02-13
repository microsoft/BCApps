// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Utilities;
using System.Threading;

/// <summary>
/// Helps with job queue management.
/// </summary>
codeunit 20455 "Qlty. Job Queue Management"
{
    var
        InspectionGenerationRuleDataItemTok: Label '/ReportParameters/DataItems/DataItem[@name=''CurrentInspectionGenerationRule'']', Locked = true;
        DataItemOfInspectionGenerationRuleTok: Label 'CurrentInspectionGenerationRule', Locked = true;
        FilterMandatoryErr: Label 'It is mandatory that an inspection generation rule have at least one filter defined to help prevent inadvertent over-generation of inspections. Navigate to the Quality Inspection Generation Rules and make sure at least one filter is set for each rule that matches the %1 schedule group.', Comment = '%1=the schedule group';
        DefaultScheduleGroupTok: Label 'QM', Locked = true;
        DoYouWantToDeleteJobQueueEntryQst: Label 'There are no rules that are configured to use the job queue entry of %1. Do you want to delete the related job queue entry?', Comment = '%1=the schedule group';
        ThereAreMultipleJobQueueEntriesPleaseReviewMsg: Label 'There are multiple job queue entries that appear related to the group of %1. Please review and adjust the job queue entry configuration if necessary.', Comment = '%1=the schedule group';
        ThereIsNoJobQueueForThisScheduleGroupYetDoYouWantToCreateQst: Label 'There is no job queue entry yet for the schedule group of %1. Do you want to create one?', Comment = '%1=the schedule group';
        JobQueueEntryMadeDoYouWantToSeeQst: Label 'A job queue entry has been made to help schedule this group of %1. Do you want to see it?', Comment = '%1=the schedule group';
        TheScheduleGroupLbl: Label 'Schedule Inspection for : %1', Comment = '%1=the schedule group';
        ThereIsAlreadyAJobQueueForThisScheduleGroupYetDoYouWantToCreateQst: Label 'There is already at least one job queue entry yet for the schedule group of %1. Do you want to create another one?', Comment = '%1=the schedule group';
        DoYouWantToSeeJobQueueEntriesQst: Label 'Do you want to see the job queue entries for the group of %1?', Comment = '%1=the schedule group';

    /// <summary>
    /// Checks whether a job queue entry already exists for a given schedule group.
    /// Uses FindJobQueueEntriesForScheduleGroup to search for matching job queue entries
    /// that are configured to run scheduled inspection generation for the specified group.
    /// </summary>
    /// <param name="ScheduleGroup">The schedule group code to check for associated job queue entries</param>
    /// <returns>True if at least one job queue entry exists for this schedule group; False otherwise</returns>
    local procedure IsJobQueueCreated(ScheduleGroup: Code[20]): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        exit(FindJobQueueEntriesForScheduleGroup(ScheduleGroup, JobQueueEntry));
    end;

    /// <summary>
    /// Ensures a job queue entry exists for the specified schedule group, creating one if missing.
    /// Behavior varies based on execution context:
    /// - If job queue already exists → exits silently without action
    /// - If interactive session (GUI) → prompts user before creating, then offers to view the entry
    /// - If non-interactive (background) → creates job queue entry automatically without prompts
    /// 
    /// Common usage: Called when setting up inspection generation rules to ensure scheduled execution infrastructure exists.
    /// </summary>
    /// <param name="ScheduleGroup">The schedule group code to check and potentially create a job queue entry for</param>
    internal procedure PromptCreateJobQueueEntryIfMissing(ScheduleGroup: Code[20])
    begin
        if IsJobQueueCreated(ScheduleGroup) then
            exit;

        if GuiAllowed() then
            if not Confirm(StrSubstNo(ThereIsNoJobQueueForThisScheduleGroupYetDoYouWantToCreateQst, ScheduleGroup)) then
                exit;

        CreateJobQueueEntry(ScheduleGroup);

        if GuiAllowed() then
            if Confirm(StrSubstNo(JobQueueEntryMadeDoYouWantToSeeQst, ScheduleGroup)) then
                RunPageLookupJobQueueEntriesForScheduleGroup(ScheduleGroup);
    end;

    /// <summary>
    /// Creates an additional job queue entry for a schedule group, with user confirmation in interactive sessions.
    /// Unlike PromptCreateJobQueueEntryIfMissing, this always creates a new entry even if one already exists,
    /// allowing multiple job queue entries with different scheduling characteristics for the same group.
    /// 
    /// Behavior:
    /// - If ScheduleGroup is empty → defaults to 'QM'
    /// - If interactive and entry exists → confirms user wants to create another one
    /// - Creates new job queue entry regardless of existing entries
    /// - If interactive → offers to display job queue entries page after creation
    /// 
    /// Common usage: When users want multiple schedules for the same rule group (e.g., hourly and daily runs).
    /// </summary>
    /// <param name="ScheduleGroup">The schedule group code to create a job queue entry for (defaults to 'QM' if empty)</param>
    internal procedure PromptCreateJobQueueEntry(ScheduleGroup: Code[20])
    begin
        if ScheduleGroup = '' then
            ScheduleGroup := DefaultScheduleGroupTok;

        if GuiAllowed() then
            if IsJobQueueCreated(ScheduleGroup) then
                if not Confirm(StrSubstNo(ThereIsAlreadyAJobQueueForThisScheduleGroupYetDoYouWantToCreateQst, ScheduleGroup)) then
                    exit;

        CreateJobQueueEntry(ScheduleGroup);

        if GuiAllowed() then
            if Confirm(StrSubstNo(DoYouWantToSeeJobQueueEntriesQst, ScheduleGroup)) then
                RunPageLookupJobQueueEntriesForScheduleGroup(ScheduleGroup);
    end;

    /// <summary>
    /// Deletes job queue entries for a schedule group if no other inspection generation rules are using them.
    /// Performs safety checks to prevent orphaned job queue entries while protecting entries still in use.
    /// 
    /// Logic flow:
    /// 1. Check if other inspection generation rules use this schedule group (excluding ToExcludeQltyInspectionGenRule)
    /// 2. If other rules exist → exit without deletion
    /// 3. Find all job queue entries for this schedule group
    /// 4. If exactly one entry found and interactive → confirm deletion with user
    /// 5. If exactly one entry → delete it
    /// 6. If multiple entries found and interactive → show message and open page for manual review
    /// 
    /// Common usage: Called when deleting or modifying inspection generation rules to clean up unused job queue entries.
    /// </summary>
    /// <param name="ToExcludeQltyInspectionGenRule">The rule to exclude from the check (typically the rule being deleted or modified)</param>
    /// <param name="ScheduleGroupToConsiderRemoving">The schedule group code whose job queue entries should be considered for removal</param>
    internal procedure DeleteJobQueueIfNothingElseIsUsingThisGroup(ToExcludeQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"; ScheduleGroupToConsiderRemoving: Code[20])
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        QltyInspectionGenRule.SetRange("Schedule Group", ScheduleGroupToConsiderRemoving);
        if ToExcludeQltyInspectionGenRule."Entry No." <> 0 then
            QltyInspectionGenRule.SetFilter("Entry No.", '<>%1', ToExcludeQltyInspectionGenRule."Entry No.");

        if not QltyInspectionGenRule.IsEmpty() then
            exit;

        if not FindJobQueueEntriesForScheduleGroup(ScheduleGroupToConsiderRemoving, JobQueueEntry) then
            exit;

        if GuiAllowed() then
            if JobQueueEntry.Count() = 1 then
                if not Confirm(StrSubstNo(DoYouWantToDeleteJobQueueEntryQst, ScheduleGroupToConsiderRemoving)) then
                    exit;

        if JobQueueEntry.Count() = 1 then begin
            JobQueueEntry.FindFirst();
            JobQueueEntry.Delete(true);
        end else
            if (JobQueueEntry.Count() > 1) and GuiAllowed() then begin
                Message(ThereAreMultipleJobQueueEntriesPleaseReviewMsg, ScheduleGroupToConsiderRemoving);
                RunPageLookupJobQueueEntriesForScheduleGroup(ScheduleGroupToConsiderRemoving);
            end;
    end;

    /// <summary>
    /// Opens the Job Queue Entries page filtered to show only entries related to a specific schedule group.
    /// Useful for users to view, modify, or troubleshoot scheduled inspection generation for a particular group.
    /// 
    /// The page will display all job queue entries configured to run the "Qlty. Schedule Inspection"
    /// report with filters matching the specified schedule group.
    /// </summary>
    /// <param name="ScheduleGroup">The schedule group code to filter job queue entries by</param>
    internal procedure RunPageLookupJobQueueEntriesForScheduleGroup(ScheduleGroup: Code[20])
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        FindJobQueueEntriesForScheduleGroup(ScheduleGroup, JobQueueEntry);
        Page.Run(Page::"Job Queue Entries", JobQueueEntry);
    end;

    /// <summary>
    /// Creates a new job queue entry configured to run scheduled inspection generation for a schedule group.
    /// Does not check for duplicates - multiple job queue entries are allowed to support different
    /// scheduling characteristics (e.g., hourly vs. daily) for the same schedule group.
    /// 
    /// Configuration applied:
    /// - Object Type: Report
    /// - Object ID: Report "Qlty. Schedule Inspection" (20412)
    /// - Report Parameters: XML filter containing schedule group criteria
    /// - Initial Status: On Hold (user must manually activate)
    /// - Description: "Schedule Inspection for : [ScheduleGroup]"
    /// - Report Request Page Options: Enabled
    /// 
    /// The entry is created in "On Hold" status so users can configure scheduling before activation.
    /// </summary>
    /// <param name="ScheduleGroup">The schedule group code to create a job queue entry for</param>
    local procedure CreateJobQueueEntry(ScheduleGroup: Code[20])
    var
        JobQueueEntry: Record "Job Queue Entry";
        FilterOnScheduleGroupQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReportParameterData: Text;
    begin
        JobQueueEntry.Init();
        JobQueueEntry.Insert(true);
        JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.Validate("Object ID to Run", Report::"Qlty. Schedule Inspection");
        FilterOnScheduleGroupQltyInspectionGenRule.SetRange("Schedule Group", ScheduleGroup);

        ReportParameterData := GetXmlFilterContents(FilterOnScheduleGroupQltyInspectionGenRule);
        JobQueueEntry.SetReportParameters(ReportParameterData);
        JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
        JobQueueEntry.Modify(true);
        JobQueueEntry."Report Request Page Options" := true;
        JobQueueEntry.Description := CopyStr(
            StrSubstNo(TheScheduleGroupLbl, ScheduleGroup), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry.Modify(false);
    end;

    /// <summary>
    /// Generates XML report parameters for job queue entries that store filter criteria for inspection generation rules.
    /// Job queue entries store report parameters as XML, and this procedure creates the properly formatted XML string.
    /// 
    /// Generated XML structure:
    /// <![CDATA[ 
    /// <?xml version="1.0" standalone="yes"?>
    /// <ReportParameters name="Qlty. Schedule Inspection" id="20412">
    ///   <DataItems>
    ///     <DataItem name="CurrentInspectionGenerationRule">VERSION(1) SORTING(Field1) WHERE(Field4=1(C))</DataItem>
    ///   </DataItems>
    /// </ReportParameters>
    /// ]]>
    /// 
    /// The inner text of the DataItem element contains the view filter string (GetView result) which specifies
    /// which inspection generation rules should be processed by the scheduled report.
    /// 
    /// IMPORTANT: If the "Qlty. Schedule Inspection" report structure changes, update:
    /// - InspectionGenerationRuleDataItemTok: XPath to the DataItem node
    /// - DataItemOfInspectionGenerationRuleTok: The name attribute value of the DataItem
    /// </summary>
    /// <param name="FilterOfQltyInspectionGenRule">The inspection generation rule record with filters applied (only filter view is used, not data)</param>
    /// <returns>XML string containing the report parameters suitable for job queue entry storage</returns>
    local procedure GetXmlFilterContents(var FilterOfQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule") XmlOfReportParameters: Text
    var
        ReportParamsXmlDocument: XmlDocument;
        NodeReportParametersXmlNode: XmlElement;
        NodeDataItemsXmlNode: XmlElement;
        NodeDataItemOfXmlNode: XmlElement;
        TextOfFilterString: XmlText;
        StandaloneXmlDeclaration: XmlDeclaration;
    begin
        ReportParamsXmlDocument := XmlDocument.Create();
        StandaloneXmlDeclaration := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        ReportParamsXmlDocument.SetDeclaration(StandaloneXmlDeclaration);
        NodeReportParametersXmlNode := XmlElement.Create('ReportParameters');
        ReportParamsXmlDocument.Add(NodeReportParametersXmlNode);
        NodeDataItemsXmlNode := XmlElement.Create('DataItems');
        NodeReportParametersXmlNode.Add(NodeDataItemsXmlNode);
        NodeDataItemOfXmlNode := XmlElement.Create('DataItem');
        NodeDataItemOfXmlNode.SetAttribute('name', DataItemOfInspectionGenerationRuleTok);

        TextOfFilterString := XmlText.Create(FilterOfQltyInspectionGenRule.GetView(false));
        NodeDataItemOfXmlNode.Add(TextOfFilterString);
        NodeDataItemsXmlNode.Add(NodeDataItemOfXmlNode);
        ReportParamsXmlDocument.WriteTo(XmlOfReportParameters);
    end;

    /// <summary>
    /// Validates that an inspection generation rule has required filters before allowing scheduled execution.
    /// Throws an error if the rule lacks mandatory filters to prevent inadvertent over-generation of inspections.
    /// 
    /// Validation logic:
    /// At least one of these filters must be specified:
    /// - Condition Filter
    /// - Item Filter
    /// - Item Attribute Filter
    /// 
    /// Rationale: Without filters, scheduled rules could generate excessive inspections for all items or conditions,
    /// potentially causing performance issues or unwanted inspection creation.
    /// 
    /// Error thrown: FilterMandatoryErr with schedule group in message
    /// </summary>
    /// <param name="ThisQltyInspectionGenRule">The inspection generation rule to validate for scheduling</param>
    internal procedure CheckIfGenerationRuleCanBeScheduled(var ThisQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    begin
        if (ThisQltyInspectionGenRule."Condition Filter" = '') and (ThisQltyInspectionGenRule."Item Filter" = '') and (ThisQltyInspectionGenRule."Item Attribute Filter" = '') then
            Error(FilterMandatoryErr, ThisQltyInspectionGenRule."Schedule Group");
    end;

    /// <summary>
    /// Finds all job queue entries associated with a specific schedule group by parsing XML report parameters.
    /// Marks matching entries and applies filters to the output record variable for easy iteration.
    /// 
    /// Search algorithm:
    /// 1. Find all job queue entries running Report "Qlty. Schedule Inspection" (20412)
    /// 2. For each entry, parse the XML report parameters
    /// 3. Extract the filter view string from the DataItem node (XPath: InspectionGenerationRuleDataItemTok)
    /// 4. Clean and apply the filter view to a temporary inspection generation rule record
    /// 5. Check if the "Schedule Group" filter matches the requested schedule group
    /// 6. Mark matching job queue entries and build ID filter
    /// 7. Return marked entries with ID filter applied
    /// 
    /// Uses ReadUncommitted isolation level for better performance with large job queue tables.
    /// The returned record variable contains only marked entries and can be iterated with FindSet/Next.
    /// </summary>
    /// <param name="ScheduleGroup">The schedule group code to search for in job queue entry report parameters</param>
    /// <param name="MarkedJobQueueEntry">Output: Record variable with marked and filtered job queue entries found</param>
    /// <returns>True if at least one matching job queue entry was found; False otherwise</returns>
    local procedure FindJobQueueEntriesForScheduleGroup(ScheduleGroup: Code[20]; var MarkedJobQueueEntry: Record "Job Queue Entry") AtLeastOne: Boolean
    var
        SearchForQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        XmlOfReportParameters: Text;
        TestFilter: Text;
        ortParamsXmlDocument: XmlDocument;
        NodeOfTestFilter: XmlNode;
        ElementOfTest: XmlElement;
        IDFilter: Text;
    begin
        Clear(MarkedJobQueueEntry);
        MarkedJobQueueEntry.Reset();
        if ScheduleGroup = '' then
            exit;

        MarkedJobQueueEntry.SetRange("Object Type to Run", MarkedJobQueueEntry."Object Type to Run"::Report);
        MarkedJobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        MarkedJobQueueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        if MarkedJobQueueEntry.FindSet() then
            repeat
                XmlOfReportParameters := MarkedJobQueueEntry.GetReportParameters();
                XmlDocument.ReadFrom(XmlOfReportParameters, ortParamsXmlDocument);
                if ortParamsXmlDocument.SelectSingleNode(InspectionGenerationRuleDataItemTok, NodeOfTestFilter) then begin
                    ElementOfTest := NodeOfTestFilter.AsXmlElement();
                    TestFilter := ElementOfTest.InnerText();
                    TestFilter := QltyFilterHelpers.CleanUpWhereClause(TestFilter);
                    if TestFilter <> '' then begin
                        Clear(SearchForQltyInspectionGenRule);
                        SearchForQltyInspectionGenRule.Reset();
                        SearchForQltyInspectionGenRule.FilterGroup(0);
                        SearchForQltyInspectionGenRule.SetView(TestFilter);
                        if SearchForQltyInspectionGenRule.GetFilter("Schedule Group") <> '' then begin
                            SearchForQltyInspectionGenRule.FilterGroup(10);
                            SearchForQltyInspectionGenRule.SetFilter("Schedule Group", ScheduleGroup);
                            SearchForQltyInspectionGenRule.FilterGroup(0);
                            if not SearchForQltyInspectionGenRule.IsEmpty() then begin
                                MarkedJobQueueEntry.Mark();
                                if StrLen(IDFilter) > 0 then
                                    IDFilter += '|';
                                IDFilter += MarkedJobQueueEntry.ID;
                                AtLeastOne := true;
                            end
                        end;
                    end;
                end;
            until MarkedJobQueueEntry.Next() = 0;

        MarkedJobQueueEntry.MarkedOnly();
        if AtLeastOne then
            MarkedJobQueueEntry.SetFilter(ID, IDFilter);
    end;
}
