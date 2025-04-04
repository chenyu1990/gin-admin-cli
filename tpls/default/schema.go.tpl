package schema

import (
	"{{.RootImportPath}}/pkg/schema"
	"time"

	{{if .TableName}}"{{.RootImportPath}}/internal/config"{{end}}
)

{{$name := .Name}}
{{$includeSequence := .Include.Sequence}}
{{$treeTpl := eq .TplType "tree"}}

{{with .Comment}}// {{.}}{{else}}// Defining the `{{$name}}` struct.{{end}}
type {{$name}} struct {
    {{- range .Fields}}{{$fieldName := .Name}}
	{{- if eq .OnlyCond false}}
    {{- if .Name}}
	{{$fieldName}} {{.Type}} `json:"{{if ne .JSONTag "-"}}{{.JSONTag}},omitempty{{else}}-{{end}}"{{with .GormTag}} gorm:"{{.}}"{{end}}{{with .CustomTag}} {{raw .}}{{end}}`{{with .Comment}}// {{.}}{{end}}
	{{- end}}
	{{- end}}
	{{- end}}
}

{{- if .TableName}}
func (a {{$name}}) TableName() string {
	return config.C.FormatTableName("{{.TableName}}")
}
{{- end}}

// Defining the query parameters for the `{{$name}}` struct.
type {{$name}}QueryParam struct {
	schema.PaginationParam
	{{if $treeTpl}}InIDs []string `form:"-"`{{- end}}
	ID  string   `form:"id"`  // 唯一标识
	IDs []string `form:"ids"` // 唯一标识
	{{- range .Fields}}{{$fieldName := .Name}}
	{{- range .Query}}
	{{- with .}}
	{{.Name}} {{.Type}} `form:"{{with .FormTag}}{{.}}{{else}}-{{end}}"{{with .BindingTag}} binding:"{{.}}"{{end}}{{with .CustomTag}} {{raw .}}{{end}}`{{with .Comment}}// {{.}}{{end}}
	{{- end}}
	{{- end}}
	{{- end}}
}

func (a *{{$name}}QueryParam) String() string {
	bytes, _ := json.Marshal(a)
	return string(bytes)
}

// Defining the query options for the `{{$name}}` struct.
type {{$name}}QueryOptions struct {
	schema.QueryOptions
}

// Defining the query result for the `{{$name}}` struct.
type {{$name}}QueryResult struct {
	Data       {{plural .Name}}
	PageResult *schema.PaginationResult
}

// Defining the slice of `{{$name}}` struct.
type {{plural .Name}} []*{{$name}}
type {{$name}}Map map[{{.MapKeyType}}]*{{$name}}

{{- if $includeSequence}}
func (a {{plural .Name}}) Len() int {
	return len(a)
}

func (a {{plural .Name}}) Less(i, j int) bool {
	if a[i].Sequence == a[j].Sequence {
		return a[i].CreatedAt.Unix() > a[j].CreatedAt.Unix()
	}
	return a[i].Sequence > a[j].Sequence
}

func (a {{plural .Name}}) Swap(i, j int) {
	a[i], a[j] = a[j], a[i]
}
{{- end}}

{{- if $treeTpl}}
func (a {{plural .Name}}) ToMap() map[string]*{{$name}} {
	m := make(map[string]*{{$name}})
	for _, item := range a {
		m[item.ID] = item
	}
	return m
}

func (a {{plural .Name}}) SplitParentIDs() []string {
	parentIDs := make([]string, 0, len(a))
	idMapper := make(map[string]struct{})
	for _, item := range a {
		if _, ok := idMapper[item.ID]; ok {
			continue
		}
		idMapper[item.ID] = struct{}{}
		if pp := item.ParentPath; pp != "" {
			for _, pid := range strings.Split(pp, TreePathDelimiter) {
				if pid == "" {
					continue
				}
				if _, ok := idMapper[pid]; ok {
					continue
				}
				parentIDs = append(parentIDs, pid)
				idMapper[pid] = struct{}{}
			}
		}
	}
	return parentIDs
}

func (a {{plural .Name}}) ToTree() {{plural .Name}} {
	var list {{plural .Name}}
	m := a.ToMap()
	for _, item := range a {
		if item.ParentID == "" {
			list = append(list, item)
			continue
		}
		if parent, ok := m[item.ParentID]; ok {
			if parent.Children == nil {
				children := {{plural .Name}}{item}
				parent.Children = &children
				continue
			}
			*parent.Children = append(*parent.Children, item)
		}
	}
	return list
}
{{- end}}

// Defining the data structure for creating a `{{$name}}` struct.
type {{$name}}Form struct {
	{{- range .Fields}}{{$fieldName := .Name}}{{$type :=.Type}}
	{{- with .Form}}
	{{.Name}} {{$type}} `json:"{{.JSONTag}}"{{with .BindingTag}} binding:"{{.}}"{{end}}{{with .CustomTag}} {{raw .}}{{end}}`{{with .Comment}}// {{.}}{{end}}
	{{- end}}
	{{- end}}
}

// A validation function for the `{{$name}}Form` struct.
func (a *{{$name}}Form) Validate() error {
	return nil
}

// Convert `{{$name}}Form` to `{{$name}}` object.
func (a *{{$name}}Form) FillTo({{lowerCamel $name}} *{{$name}}) error {
	{{- range .Fields}}{{$fieldName := .Name}}
	{{- with .Form}}
	{{lowerCamel $name}}.{{$fieldName}} = a.{{.Name}}
	{{- end}}
    {{- end}}
	return nil
}
