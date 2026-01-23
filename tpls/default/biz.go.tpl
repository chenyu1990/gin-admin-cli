package biz

import (
	"context"
	"time"

	"{{.ModuleImportPath}}/dal"
	"{{.ModuleImportPath}}/schema"
	"{{.RootImportPath}}/pkg/dbx"
	"{{.RootImportPath}}/pkg/errors"
	pkgSchema "{{.RootImportPath}}/pkg/schema"
)

{{$name := .Name}}
{{$includeID := .Include.ID}}
{{$includeCreatedAt := .Include.CreatedAt}}
{{$includeUpdatedAt := .Include.UpdatedAt}}
{{$includeStatus := .Include.Status}}
{{$treeTpl := eq .TplType "tree"}}

type {{$name}} struct {
	Trans       *dbx.Trans
	{{$name}}DAL *dal.{{$name}}
}

func (a *{{$name}}) Query(ctx context.Context, params schema.{{$name}}QueryParam) (*schema.{{$name}}QueryResult, error) {
	params.Pagination = {{if .DisablePagination}}false{{else}}true{{end}}

	result, err := a.{{$name}}DAL.Query(ctx, params, schema.{{$name}}QueryOptions{
		QueryOptions: pkgSchema.QueryOptions{
			OrderFields: []pkgSchema.OrderField{
                {{- range .Fields}}{{$fieldName := .Name}}
				{{- if .Order}}
				{Field: "{{lowerUnderline $fieldName}}", Direction: {{if eq .Order "DESC"}}pkgSchema.DESC{{else}}pkgSchema.ASC{{end}}},
				{{- end}}
                {{- end}}
			},
			MustWhere: true,
		},
	})
	if err != nil {
		return nil, err
	}
	{{- if $treeTpl}}
	result.Data = result.Data.ToTree()
	sort.Sort(result.Data)
	{{- end}}
	return result, nil
}

{{- if $treeTpl}}
func (a *{{$name}}) appendChildren(ctx context.Context, data schema.{{plural .Name}}) (schema.{{plural .Name}}, error) {
	if len(data) == 0 {
		return data, nil
	}

	existsInData := func(id string) bool {
		for _, item := range data {
			if item.ID == id {
				return true
			}
		}
		return false
	}

	for _, item := range data {
		childResult, err := a.{{$name}}DAL.Query(ctx, schema.{{$name}}QueryParam{
			ParentPathPrefix: item.ParentPath + item.ID + schema.TreePathDelimiter,
		})
		if err != nil {
			return nil, err
		}
		for _, child := range childResult.Data {
			if existsInData(child.ID) {
				continue
			}
			data = append(data, child)
		}
	}

	parentIDs := data.SplitParentIDs()
	if len(parentIDs) > 0 {
		parentResult, err := a.{{$name}}DAL.Query(ctx, schema.{{$name}}QueryParam{
			InIDs: parentIDs,
		})
		if err != nil {
			return nil, err
		}
		for _, p := range parentResult.Data {
			if existsInData(p.ID) {
				continue
			}
			data = append(data, p)
		}
		sort.Sort(data)
	}

	return data, nil
}
{{- end}}

func (a *{{$name}}) Get(ctx context.Context, id string) (*schema.{{$name}}, error) {
	{{lowerCamel $name}}, err := a.{{$name}}DAL.Get(ctx, id)
	if err != nil {
		return nil, err
	} else if {{lowerCamel $name}} == nil {
		return nil, errors.NotFound("", "{{titleSpace $name}} not found")
	}
	return {{lowerCamel $name}}, nil
}

func (a *{{$name}}) Create(ctx context.Context, formItem *schema.{{$name}}Form) (*schema.{{$name}}, error) {
	{{lowerCamel $name}} := &schema.{{$name}}{
		{{if $includeID}}ID:          util.NewXID(),{{end}}
		{{if $includeCreatedAt}}CreatedAt:   time.Now(),{{end}}
	}

	{{- range .Fields}}
	{{- if .Unique}}
	{{- if $treeTpl}}
	if exists,err := a.{{$name}}DAL.Exists{{.Name}}(ctx, formItem.ParentID, formItem.{{.Name}}); err != nil {
		return nil, err
	} else if exists {
		return nil, errors.BadRequest("", "{{.Name}} already exists")
	}
	{{- else}}
	if exists,err := a.{{$name}}DAL.Exists{{.Name}}(ctx, formItem.{{.Name}}); err != nil {
		return nil, err
	} else if exists {
		return nil, errors.BadRequest("", "{{.Name}} already exists")
	}
	{{- end}}
	{{- end}}
	{{- end}}

	{{- if $treeTpl}}
	if parentID := formItem.ParentID; parentID != "" {
		parent, err := a.{{$name}}DAL.Get(ctx, parentID)
		if err != nil {
			return nil, err
		} else if parent == nil {
			return nil, errors.NotFound("", "Parent not found")
		}
		{{lowerCamel $name}}.ParentPath = parent.ParentPath + parent.ID + schema.TreePathDelimiter
	}
	{{- end}}

	if err := formItem.FillTo({{lowerCamel $name}}); err != nil {
		return nil, err
	}

	err := a.Trans.Exec(ctx, func(ctx context.Context) error {
		if err := a.{{$name}}DAL.Create(ctx, {{lowerCamel $name}}); err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	{{- if .MapKeyType }}
	a.{{$name}}DAL.CacheSet(ctx, {{lowerCamel $name}})
	{{- end}}
	return {{lowerCamel $name}}, nil
}

func (a *{{$name}}) Update(ctx context.Context, id string, formItem *schema.{{$name}}Form) error {
	{{lowerCamel $name}}, err := a.{{$name}}DAL.Get(ctx, id)
	if err != nil {
		return err
	} else if {{lowerCamel $name}} == nil {
		return errors.NotFound("", "{{titleSpace $name}} not found")
	}

	{{- range .Fields}}
	{{- if .Unique}}
	{{- if $treeTpl}}
	if {{lowerCamel $name}}.{{.Name}} != formItem.{{.Name}} {
		if exists,err := a.{{$name}}DAL.Exists{{.Name}}(ctx, formItem.ParentID, formItem.{{.Name}}); err != nil {
			return err
		} else if exists {
			return errors.BadRequest("", "{{.Name}} already exists")
		}
	}
	{{- else}}
	if {{lowerCamel $name}}.{{.Name}} != formItem.{{.Name}} {
		if exists,err := a.{{$name}}DAL.Exists{{.Name}}(ctx, formItem.{{.Name}}); err != nil {
			return err
		} else if exists {
			return errors.BadRequest("", "{{.Name}} already exists")
		}
	}
	{{- end}}
	{{- end}}
	{{- end}}

	{{- if $treeTpl}}
	oldParentPath := {{lowerCamel $name}}.ParentPath
	{{- if $includeStatus}}
	oldStatus := {{lowerCamel $name}}.Status
	{{- end}}
	var childData schema.{{plural .Name}}
	if {{lowerCamel $name}}.ParentID != formItem.ParentID {
		if parentID := formItem.ParentID; parentID != "" {
			parent, err := a.{{$name}}DAL.Get(ctx, parentID)
			if err != nil {
				return err
			} else if parent == nil {
				return errors.NotFound("", "Parent not found")
			}
			{{lowerCamel $name}}.ParentPath = parent.ParentPath + parent.ID + schema.TreePathDelimiter
		} else {
			{{lowerCamel $name}}.ParentPath = ""
		}

		childResult, err := a.{{$name}}DAL.Query(ctx, schema.{{$name}}QueryParam{
			ParentPathPrefix: oldParentPath + {{lowerCamel $name}}.ID + schema.TreePathDelimiter,
		}, schema.{{$name}}QueryOptions{
			QueryOptions: util.QueryOptions{
				SelectFields: []string{"id", "parent_path"},
			},
		})
		if err != nil {
			return err
		}
		childData = childResult.Data
	}
	{{- end}}

    if err := formItem.FillTo({{lowerCamel $name}}); err != nil {
		return err
	}
    {{if $includeUpdatedAt}}{{lowerCamel $name}}.UpdatedAt = time.Now(){{end}}
	
	err = a.Trans.Exec(ctx, func(ctx context.Context) error {
		if err := a.{{$name}}DAL.Update(ctx, {{lowerCamel $name}}); err != nil {
			return err
		}

		{{- if $treeTpl}}
		{{- if $includeStatus}}
		if oldStatus != formItem.Status {
			opath := oldParentPath + {{lowerCamel $name}}.ID + schema.TreePathDelimiter
			if err := a.{{$name}}DAL.UpdateStatusByParentPath(ctx, opath, formItem.Status); err != nil {
				return err
			}
		}
		{{- end}}

		for _, child := range childData {
			opath := oldParentPath + {{lowerCamel $name}}.ID + schema.TreePathDelimiter
			npath := {{lowerCamel $name}}.ParentPath + {{lowerCamel $name}}.ID + schema.TreePathDelimiter
			err := a.{{$name}}DAL.UpdateParentPath(ctx, child.ID, strings.Replace(child.ParentPath, opath, npath, 1))
			if err != nil {
				return err
			}
		}
		{{- end}}
		return nil
	})
	if err != nil {
		return err
	}

	{{- if .MapKeyType }}
	a.{{$name}}DAL.CacheSet(ctx, {{lowerCamel $name}})
	{{- end}}
	return nil
}

func (a *{{$name}}) Delete(ctx context.Context, id string) error {
	{{- if $treeTpl}}
	{{lowerCamel $name}}, err := a.{{$name}}DAL.Get(ctx, id)
	if err != nil {
		return err
	} else if {{lowerCamel $name}} == nil {
		return errors.NotFound("", "{{titleSpace $name}} not found")
	}

	childResult, err := a.{{$name}}DAL.Query(ctx, schema.{{$name}}QueryParam{
		ParentPathPrefix: {{lowerCamel $name}}.ParentPath + {{lowerCamel $name}}.ID + schema.TreePathDelimiter,
		}, schema.{{$name}}QueryOptions{
		QueryOptions: util.QueryOptions{
			SelectFields: []string{"id"},
		},
	})
	if err != nil {
		return err
	}
	{{- else}}
	exists, err := a.{{$name}}DAL.Exists(ctx, id)
	if err != nil {
		return err
	} else if !exists {
		return errors.NotFound("", "{{titleSpace $name}} not found")
	}
	{{- end}}

	err = a.Trans.Exec(ctx, func(ctx context.Context) error {
		if _, err := a.{{$name}}DAL.Delete(ctx, id); err != nil {
			return err
		}
		{{- if $treeTpl}}
		for _, child := range childResult.Data {
			if err := a.{{$name}}DAL.Delete(ctx, child.ID); err != nil {
				return err
			}
		}
		{{- end}}
		return nil
	})
	if err != nil {
		return err
	}

	{{- if .MapKeyType }}
	a.{{$name}}DAL.CacheRemove(ctx, id)
	{{- end}}
	return nil
}
