namespace Microsoft.Service.Test;

using Microsoft.Service.Document;

pageextension 136302 "Service Lines Job Test" extends "Service Lines"
{
    layout
    {
        modify("Job No.")
        {
            Visible = true;
        }
        modify("Job Task No.")
        {
            Visible = true;
        }
    }
}