let
    Source = Contacts,
    Active = Table.SelectRows(Source, each [Status] = "Active"),
    Norm = (x as any) as nullable text => let t = if x = null then "" else Text.Lower(Text.Trim(Text.From(x))) in if t = "" then null else t,
    Reg = Table.AddColumn(Active, "RegKey", each Norm([RegistrationID]), type nullable text),
    Keys = Table.AddColumn(Reg, "EmailKey", each Norm([Email]), type nullable text),
    RG = Table.Group(Table.SelectRows(Keys, each [RegKey] <> null), {"RegKey"}, {{"RegCount", each Table.RowCount(_), Int64.Type}}),
    EG = Table.Group(Table.SelectRows(Keys, each [EmailKey] <> null), {"EmailKey"}, {{"EmailCount", each Table.RowCount(_), Int64.Type}}),
    RJ = Table.NestedJoin(Keys, {"RegKey"}, RG, {"RegKey"}, "RegGroup", JoinKind.LeftOuter),
    RE = Table.ExpandTableColumn(RJ, "RegGroup", {"RegCount"}, {"RegCount"}),
    EJ = Table.NestedJoin(RE, {"EmailKey"}, EG, {"EmailKey"}, "EmailGroup", JoinKind.LeftOuter),
    EE = Table.ExpandTableColumn(EJ, "EmailGroup", {"EmailCount"}, {"EmailCount"}),
    Checks = Table.AddColumn(EE, "IssueType", each List.RemoveNulls({
        if [IsAdvisor] = "Yes" and [RegKey] = null then "Missing registration ID" else null,
        if [RegKey] <> null and (if [RegCount] = null then 0 else [RegCount]) > 1 then "Duplicate registration ID" else null,
        if [EmailKey] <> null and (if [EmailCount] = null then 0 else [EmailCount]) > 1 then "Duplicate email" else null,
        if Norm([ContactSegment]) <> null and Norm([CompanySegment]) <> null and Norm([ContactSegment]) <> Norm([CompanySegment]) then "Segment mismatch" else null,
        if Norm([FullName]) = null or [EmailKey] = null then "Incomplete contact" else null
    }), type list),
    Select = Table.SelectColumns(Checks, {"RecordID", "IssueType"}),
    Expand = Table.ExpandListColumn(Select, "IssueType"),
    Nonblank = Table.SelectRows(Expand, each [IssueType] <> null),
    Types = Table.TransformColumnTypes(Nonblank, {{"RecordID", type text}, {"IssueType", type text}})
in
    Types
