namespace System.Threading;

/// <summary>
/// Specifies the priority of a job in the job queue. Only used for jobs with a Category Code, which is used for serialization of jobs.
/// </summary>
enum 470 "Job Queue Priority"
{
    Extensible = true;
    Caption = 'Job Queue Priority';

    value(1000; "High") { Caption = 'High'; }
    value(2000; "Normal") { Caption = 'Normal'; }
    value(3000; "Low") { Caption = 'Low'; }
}