namespace System.Automation;

using Microsoft.Finance.GeneralLedger.Journal;
using System;
using System.Reflection;
using System.Security.User;

xmlport 1501 "Import / Export Workflow"
{
    Caption = 'Import / Export Workflow';

    schema
    {
        textelement(Root)
        {
            tableelement(Workflow; Workflow)
            {
                MaxOccurs = Unbounded;
                XmlName = 'Workflow';
                fieldattribute(Code; Workflow.Code)
                {
                }
                fieldattribute(Description; Workflow.Description)
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if Workflow.Description = '' then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(Template; Workflow.Template)
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if not Workflow.Template then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(Category; Workflow.Category)
                {
                    FieldValidate = no;
                }
                tableelement("Workflow Step"; "Workflow Step")
                {
                    LinkFields = "Workflow Code" = field(Code);
                    LinkTable = Workflow;
                    MinOccurs = Zero;
                    XmlName = 'WorkflowStep';
                    fieldattribute(StepID; "Workflow Step".ID)
                    {
                    }
                    fieldattribute(StepDescription; "Workflow Step".Description)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassField()
                        begin
                            if "Workflow Step".Description = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textattribute(EntryPoint)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            if "Workflow Step"."Entry Point" = false then
                                currXMLport.Skip();

                            EntryPoint := Format("Workflow Step"."Entry Point", 0, 2);
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Evaluate("Workflow Step"."Entry Point", EntryPoint);
                        end;
                    }
                    fieldattribute(PreviousStepID; "Workflow Step"."Previous Workflow Step ID")
                    {
                        FieldValidate = no;
                    }
                    fieldattribute(NextStepID; "Workflow Step"."Next Workflow Step ID")
                    {
                        FieldValidate = no;
                        Occurrence = Optional;

                        trigger OnBeforePassField()
                        begin
                            if "Workflow Step"."Next Workflow Step ID" = 0 then
                                currXMLport.Skip();
                        end;
                    }
                    textattribute(Type)
                    {

                        trigger OnBeforePassVariable()
                        begin
                            Type := Format("Workflow Step".Type, 0, 2);
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Evaluate("Workflow Step".Type, Type);
                        end;
                    }
                    fieldattribute(FunctionName; "Workflow Step"."Function Name")
                    {
                    }
                    fieldattribute(SequenceNo; "Workflow Step"."Sequence No.")
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassField()
                        begin
                            if "Workflow Step"."Sequence No." = 0 then
                                currXMLport.Skip();
                        end;
                    }
                    tableelement("Workflow Step Argument"; "Workflow Step Argument")
                    {
                        LinkFields = ID = field(Argument), Type = field(Type);
                        LinkTable = "Workflow Step";
                        MaxOccurs = Once;
                        MinOccurs = Zero;
                        XmlName = 'WorkflowStepArgument';
                        fieldattribute(GeneralJournalTemplateName; "Workflow Step Argument"."General Journal Template Name")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."General Journal Template Name" = '' then
                                    currXMLport.Skip();
                            end;

                            trigger OnAfterAssignField()
                            var
                                GenJournalTemplate: Record "Gen. Journal Template";
                            begin
                                if not GenJournalTemplate.Get("Workflow Step Argument"."General Journal Batch Name") then
                                    "Workflow Step Argument"."General Journal Batch Name" := '';
                            end;
                        }
                        fieldattribute(GeneralJournalBatchName; "Workflow Step Argument"."General Journal Batch Name")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."General Journal Batch Name" = '' then
                                    currXMLport.Skip();
                            end;

                            trigger OnAfterAssignField()
                            var
                                GenJournalBatch: Record "Gen. Journal Batch";
                            begin
                                if not GenJournalBatch.Get("Workflow Step Argument"."General Journal Template Name",
                                     "Workflow Step Argument"."General Journal Batch Name")
                                then
                                    "Workflow Step Argument"."General Journal Batch Name" := '';
                            end;
                        }
                        fieldattribute(ResponseFunctionName; "Workflow Step Argument"."Response Function Name")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Response Function Name" = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(LinkTargetPage; "Workflow Step Argument"."Link Target Page")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Link Target Page" = 0 then
                                    currXMLport.Skip();
                            end;

                            trigger OnAfterAssignField()
                            var
                                AllObjWithCaption: Record AllObjWithCaption;
                            begin
                                if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, "Workflow Step Argument"."Link Target Page") then
                                    "Workflow Step Argument"."Link Target Page" := 0;
                            end;
                        }
                        fieldattribute(CustomLink; "Workflow Step Argument"."Custom Link")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Custom Link" = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textattribute(EventConditions)
                        {
                            Occurrence = Optional;
                            TextType = BigText;

                            trigger OnBeforePassVariable()
                            var
                                InStream: InStream;
                                Convert: DotNet Convert;
                                Encoding: DotNet Encoding;
                                Conditions: Text;
                            begin
                                if not "Workflow Step Argument"."Event Conditions".HasValue() then
                                    currXMLport.Skip();

                                "Workflow Step Argument".CalcFields("Event Conditions");
                                "Workflow Step Argument"."Event Conditions".CreateInStream(InStream, TextEncoding::UTF8);
                                InStream.ReadText(Conditions);
                                Clear(EventConditions);
                                EventConditions.AddText(Convert.ToBase64String(Encoding.Unicode.GetBytes(Conditions)));
                            end;

                            trigger OnAfterAssignVariable()
                            var
                                OutStream: OutStream;
                                Convert: DotNet Convert;
                                Encoding: DotNet Encoding;
                            begin
                                if EventConditions.Length = 0 then
                                    currXMLport.Skip();

                                "Workflow Step Argument"."Event Conditions".CreateOutStream(OutStream, TextEncoding::UTF8);
                                OutStream.WriteText(Encoding.Unicode.GetString(Convert.FromBase64String(EventConditions)));
                            end;
                        }
                        textattribute(ApproverType)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassVariable()
                            begin
                                if "Workflow Step Argument"."Approver Type" = "Workflow Approver Type"::"Salesperson/Purchaser" then
                                    currXMLport.Skip();

                                ApproverType := Format("Workflow Step Argument"."Approver Type", 0, 2);
                            end;

                            trigger OnAfterAssignVariable()
                            begin
                                Evaluate("Workflow Step Argument"."Approver Type", ApproverType);
                            end;
                        }
                        textattribute(ApproverLimitType)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassVariable()
                            begin
                                if "Workflow Step Argument"."Approver Limit Type" = "Workflow Approver Limit Type"::"Approver Chain" then
                                    currXMLport.Skip();

                                ApproverLimitType := Format("Workflow Step Argument"."Approver Limit Type", 0, 2);
                            end;

                            trigger OnAfterAssignVariable()
                            begin
                                Evaluate("Workflow Step Argument"."Approver Limit Type", ApproverLimitType);
                            end;
                        }
                        fieldattribute(WorkflowUserGroupCode; "Workflow Step Argument"."Workflow User Group Code")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Workflow User Group Code" = '' then
                                    currXMLport.Skip();
                            end;

                            trigger OnAfterAssignField()
                            var
                                WorkflowUserGroup: Record "Workflow User Group";
                            begin
                                if not WorkflowUserGroup.Get("Workflow Step Argument"."Workflow User Group Code") then
                                    "Workflow Step Argument"."Workflow User Group Code" := '';
                            end;
                        }
                        textattribute(DueDateFormula)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassVariable()
                            begin
                                if Format("Workflow Step Argument"."Due Date Formula") = '' then
                                    currXMLport.Skip();

                                DueDateFormula := Format("Workflow Step Argument"."Due Date Formula");
                            end;

                            trigger OnAfterAssignVariable()
                            begin
                                if not Evaluate("Workflow Step Argument"."Due Date Formula", DueDateFormula) then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(Message; "Workflow Step Argument".Message)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument".Message = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textattribute(DelegateAfter)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassVariable()
                            begin
                                if "Workflow Step Argument"."Delegate After" = 0 then
                                    currXMLport.Skip();

                                DelegateAfter := Format("Workflow Step Argument"."Delegate After", 0, 2);
                            end;

                            trigger OnAfterAssignVariable()
                            begin
                                Evaluate("Workflow Step Argument"."Delegate After", DelegateAfter);
                            end;
                        }
                        fieldattribute(ShowConfirmationMessage; "Workflow Step Argument"."Show Confirmation Message")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if not "Workflow Step Argument"."Show Confirmation Message" then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(TableNumber; "Workflow Step Argument"."Table No.")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Table No." = 0 then
                                    currXMLport.Skip();
                            end;

                            trigger OnAfterAssignField()
                            var
                                AllObjWithCaption: Record AllObjWithCaption;
                            begin
                                if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, "Workflow Step Argument"."Table No.") then
                                    "Workflow Step Argument"."Table No." := 0;
                            end;
                        }
                        fieldattribute(FieldNumber; "Workflow Step Argument"."Field No.")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Field No." = 0 then
                                    currXMLport.Skip();
                            end;

                            trigger OnAfterAssignField()
                            var
                                "Field": Record "Field";
                                TypeHelper: Codeunit "Type Helper";
                            begin
                                if not TypeHelper.GetField("Workflow Step Argument"."Table No.", "Workflow Step Argument"."Field No.", Field) then
                                    "Workflow Step Argument"."Field No." := 0;
                            end;
                        }
                        fieldattribute(ResponseOptionGroup; "Workflow Step Argument"."Response Option Group")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Response Option Group" = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(ApproverUserID; "Workflow Step Argument"."Approver User ID")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Approver User ID" = '' then
                                    currXMLport.Skip();
                            end;

                            trigger OnAfterAssignField()
                            var
                                UserSetup: Record "User Setup";
                            begin
                                if not UserSetup.Get("Workflow Step Argument"."Approver User ID") then
                                    "Workflow Step Argument"."Approver User ID" := '';
                            end;
                        }
                        fieldattribute(NotificationUserID; "Workflow Step Argument"."Notification User ID")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Notification User ID" = '' then
                                    currXMLport.Skip();
                            end;

                            trigger OnAfterAssignField()
                            var
                                UserSetup: Record "User Setup";
                            begin
                                if not UserSetup.Get("Workflow Step Argument"."Notification User ID") then
                                    "Workflow Step Argument"."Notification User ID" := '';
                            end;
                        }
                        fieldattribute(NotificationEntryType; "Workflow Step Argument"."Notification Entry Type")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Workflow Step Argument"."Notification Entry Type" = "Workflow Step Argument"."Notification Entry Type"::"New Record" then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(NotifySender; "Workflow Step Argument"."Notify Sender")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if not "Workflow Step Argument"."Notify Sender" then
                                    currXMLport.Skip();
                            end;
                        }
                        trigger OnAfterInsertRecord()
                        begin
                            "Workflow Step".Argument := "Workflow Step Argument".ID;
                        end;
                    }
                    tableelement("Workflow Rule"; "Workflow Rule")
                    {
                        LinkFields = "Workflow Code" = field("Workflow Code"), "Workflow Step ID" = field(ID);
                        LinkTable = "Workflow Step";
                        MinOccurs = Zero;
                        XmlName = 'WorkflowRule';
                        fieldattribute(RuleID; "Workflow Rule".ID)
                        {
                        }
                        fieldattribute(RuleTableNumber; "Workflow Rule"."Table ID")
                        {
                        }
                        fieldattribute(RuleFieldNumber; "Workflow Rule"."Field No.")
                        {
                        }
                        textattribute(Operator)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassVariable()
                            begin
                                Operator := Format("Workflow Rule".Operator, 0, 2);
                            end;

                            trigger OnAfterAssignVariable()
                            begin
                                Evaluate("Workflow Rule".Operator, Operator);
                            end;
                        }
                    }
                }
                tableelement("Workflow Category"; "Workflow Category")
                {
                    AutoSave = false;
                    LinkFields = Code = field(Category);
                    LinkTable = Workflow;
                    LinkTableForceInsert = false;
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    XmlName = 'WorkflowCategory';
                    fieldattribute(CategoryCode; "Workflow Category".Code)
                    {
                    }
                    fieldattribute(CategoryDescription; "Workflow Category".Description)
                    {

                        trigger OnAfterAssignField()
                        begin
                            if "Workflow Category".Insert() then;
                        end;
                    }
                }

                trigger OnBeforeInsertRecord()
                begin
                    if (ToWorkflowCode = '') and (Workflow.Code = '') then
                        Error(EmptyCodeErr);

                    if ToWorkflowCode <> '' then
                        Workflow.Code := ToWorkflowCode;
                end;
            }
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

    var
        ToWorkflowCode: Code[20];
        EmptyCodeErr: Label 'The file could not be imported because a blank Workflow Code tag was found in the file. The import file must provide a valid workflow code for every workflow.';

    procedure InitWorkflow(NewWorkflowCode: Code[20])
    begin
        ToWorkflowCode := NewWorkflowCode;
    end;
}

