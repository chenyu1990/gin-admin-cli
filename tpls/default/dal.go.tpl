package dal

import (
	"context"

	"{{.UtilImportPath}}"
	"{{.ModuleImportPath}}/schema"
	"{{.RootImportPath}}/pkg/dbx"
	"{{.RootImportPath}}/pkg/errors"
	"gorm.io/gorm"
)

{{$name := .Name}}
{{$includeCreatedAt := .Include.CreatedAt}}
{{$includeStatus := .Include.Status}}
{{$treeTpl := eq .TplType "tree"}}

// Get {{lowerSpace .Name}} storage instance
func Get{{$name}}DB(ctx context.Context, defDB *gorm.DB) *gorm.DB {
	return dbx.GetDB(ctx, defDB).Model(new(schema.{{$name}}))
}

{{with .Comment}}// {{.}}{{else}}// Defining the `{{$name}}` data access object.{{end}}
type {{$name}} struct {
	DB *gorm.DB
	cacheTime time.Time         `wire:"-"`
	cacheMap  schema.{{$name}}Map `wire:"-"`
}

func (a *{{$name}}) getQueryOption(opts ...schema.{{$name}}QueryOptions) schema.{{$name}}QueryOptions {
	var opt schema.{{$name}}QueryOptions
	if len(opts) > 0 {
		opt = opts[0]
	}
	return opt
}

func (a *{{$name}}) where(ctx context.Context, db *gorm.DB, params *schema.{{$name}}QueryParam, opts ...schema.{{$name}}QueryOptions) (*gorm.DB, error) {
	{{- if $treeTpl}}
	if v:= params.InIDs; len(v) > 0 {
		db = db.Where("id IN ?", v)
	}
	{{- end}}
	if v := params.ID; v != "" {
		db = db.Where("`id` = ?", v)
	}
	if v := params.IDs; len(v) > 0 {
		db = db.Where("`id` IN (?)", v)
	}
    {{- range .Fields}}{{$type := .Type}}{{$fieldName := .Name}}
    {{- range .Query}}
    {{- with .}}
	if v := params.{{.Name}}; {{with .IfCond}}{{.}}{{else}}{{convIfCond $type}}{{end}} {
		db = db.Where("`{{lowerUnderline $fieldName}}` {{.OP}} {{if eq .OP "IN"}}(?){{else}}?{{end}}", {{if .Args}}{{raw .Args}}{{else}}{{if eq .OP "LIKE"}}"%"+v+"%"{{else}}v{{end}}{{end}})
	}
    {{- end}}
    {{- end}}
    {{- end}}

	if params.Pagination == false {
		for _, opt := range opts {
			if opt.MustWhere {
				_, ok := db.Statement.Clauses["WHERE"]
				if !ok {
					return nil, errors.BadRequest("", "必须有查询条件")
				}
				break
			}
		}
	}
	return db, nil
}

// Query {{lowerSpacePlural .Name}} from the database based on the provided parameters and options.
func (a *{{$name}}) Query(ctx context.Context, params schema.{{$name}}QueryParam, opts ...schema.{{$name}}QueryOptions) (*schema.{{$name}}QueryResult, error) {
	var opt schema.{{$name}}QueryOptions
	if len(opts) > 0 {
		opt = opts[0]
	}

	db := Get{{$name}}DB(ctx, a.DB)
	var err error
    db, err = a.where(ctx, db, &params, opts...)
	if err != nil {
		return nil, err
	}

	var list schema.{{plural .Name}}
	pageResult, err := dbx.WrapPageQuery(ctx, db, params.PaginationParam, opt.QueryOptions, &list)
	if err != nil {
		return nil, errors.WithStack(err)
	}

	queryResult := &schema.{{$name}}QueryResult{
		PageResult: pageResult,
		Data:       list,
	}
	return queryResult, nil
}

// Get the specified {{lowerSpace .Name}} from the database.
func (a *{{$name}}) Get(ctx context.Context, id string, opts ...schema.{{$name}}QueryOptions) (*schema.{{$name}}, error) {
	opt := a.getQueryOption(opts...)

	item := new(schema.{{$name}})
	ok, err := dbx.FindOne(ctx, Get{{$name}}DB(ctx, a.DB).Where("id=?", id), opt.QueryOptions, item)
	if err != nil {
		return nil, errors.WithStack(err)
	} else if !ok {
		return nil, nil
	}
	return item, nil
}

func (a *{{$name}}) GetSearch(ctx context.Context, params *schema.{{$name}}QueryParam, opts ...schema.{{$name}}QueryOptions) (*schema.{{$name}}, error) {
	opt := a.getQueryOption(opts...)

	item := new(schema.{{$name}})
	db, err := a.where(ctx, Get{{$name}}DB(ctx, a.DB), params)
	if err != nil {
        return nil, errors.WithStack(err)
    }
	ok, err := dbx.FindOne(ctx, db, opt.QueryOptions, item)
	if err != nil {
		return nil, errors.WithStack(err)
	} else if !ok {
		return nil, nil
	}

	return item, nil
}

// Exists checks if the specified {{lowerSpace .Name}} exists in the database.
func (a *{{$name}}) Exists(ctx context.Context, id string) (bool, error) {
	ok, err := dbx.Exists(ctx, Get{{$name}}DB(ctx, a.DB).Where("id=?", id))
	return ok, errors.WithStack(err)
}

{{- range .Fields}}
{{- if .Unique}}
{{- if $treeTpl}}
// Exist checks if the specified {{lowerSpace .Name}} exists in the database.
func (a *{{$name}}) Exists{{.Name}}(ctx context.Context, parentID string, {{lowerCamel .Name}} string) (bool, error) {
	ok, err := dbx.Exists(ctx, Get{{$name}}DB(ctx, a.DB).Where("parent_id=? AND {{lowerUnderline .Name}}=?", parentID, {{lowerCamel .Name}}))
	return ok, errors.WithStack(err)
}
{{- else}}
// Exist checks if the specified {{lowerSpace .Name}} exists in the database.
func (a *{{$name}}) Exists{{.Name}}(ctx context.Context, {{lowerCamel .Name}} string) (bool, error) {
	ok, err := dbx.Exists(ctx, Get{{$name}}DB(ctx, a.DB).Where("{{lowerUnderline .Name}}=?", {{lowerCamel .Name}}))
	return ok, errors.WithStack(err)
}
{{- end}}
{{- end}}
{{- end}}

// Create a new {{lowerSpace .Name}}.
func (a *{{$name}}) Create(ctx context.Context, item *schema.{{$name}}, opts ...schema.{{$name}}QueryOptions) error {
    db := Get{{$name}}DB(ctx, a.DB)
	opt := a.getQueryOption(opts...)
	if len(opt.OmitFields) > 0 {
		db = db.Omit(opt.OmitFields...)
	}
	result := db.Create(item)
	return errors.WithStack(result.Error)
}

// Update the specified {{lowerSpace .Name}} in the database.
func (a *{{$name}}) Update(ctx context.Context, item *schema.{{$name}}, opts ...schema.{{$name}}QueryOptions) error {
    db := Get{{$name}}DB(ctx, a.DB).Where("id=?", item.ID)
	opt := a.getQueryOption(opts...)
	if len(opt.SelectFields) > 0 {
		db = db.Select(opt.SelectFields)
	} else {
		db = db.Select("*").Omit("created_at")
	}
	result := db.Updates(item)
    return errors.WithStack(result.Error)
}

func (a *{{$name}}) Updates(ctx context.Context, params *schema.{{$name}}QueryParam, item *schema.{{$name}}) error {
    db, err := a.where(ctx, Get{{$name}}DB(ctx, a.DB), params)
	if err != nil {
		return errors.WithStack(err)
	}
	result := db.Updates(item)
	return errors.WithStack(result.Error)
}

// Delete the specified {{lowerSpace .Name}} from the database.
func (a *{{$name}}) Delete(ctx context.Context, id string) error {
	result := Get{{$name}}DB(ctx, a.DB).Where("id=?", id).Delete(new(schema.{{$name}}))
	return errors.WithStack(result.Error)
}

func (a *{{$name}}) Deletes(ctx context.Context, params *schema.{{$name}}QueryParam) error {
    db, err := a.where(ctx, Get{{$name}}DB(ctx, a.DB), params)
	if err != nil {
		return errors.WithStack(err)
	}
	result := db.Delete(new(schema.{{$name}}))
	return errors.WithStack(result.Error)
}

func (a *{{$name}}) GetMap(ctx context.Context) (schema.{{$name}}Map, error) {
	if a.cacheMap == nil {
		a.cacheMap = make(schema.{{$name}}Map)
	}

	now := time.Now()
	if a.cacheTime.Add(5 * time.Second).After(now) {
		return a.cacheMap, nil
	}
	{{lowerSpace .Name}}QueryResult, err := a.Query(ctx, schema.{{$name}}QueryParam{}, schema.{{$name}}QueryOptions{
		QueryOptions: pkgSchema.QueryOptions{
			OrderFields: []pkgSchema.OrderField{
				//{Field: "sequence", Direction: pkgSchema.DESC},
			},
		},
	})
	if err != nil {
		return nil, err
	}

	{{lowerSpace .Name}}Map := make(schema.{{$name}}Map)
	for _, {{lowerSpace .Name}} := range {{lowerSpace .Name}}QueryResult.Data {
		{{lowerSpace .Name}}Map[{{lowerSpace .Name}}.ID] = {{lowerSpace .Name}}
	}


	a.cacheMap = {{lowerSpace .Name}}Map
	a.cacheTime = now
	return {{lowerSpace .Name}}Map, nil
}

{{- if $treeTpl}}
// Updates the parent path of the specified {{lowerSpace .Name}}.
func (a *{{$name}}) UpdateParentPath(ctx context.Context, id, parentPath string) error {
	result := Get{{$name}}DB(ctx, a.DB).Where("id=?", id).Update("parent_path", parentPath)
	return errors.WithStack(result.Error)
}

{{- if $includeStatus}}
// Updates the status of all {{lowerPlural .Name}} whose parent path starts with the provided parent path.
func (a *{{$name}}) UpdateStatusByParentPath(ctx context.Context, parentPath, status string) error {
	result := Get{{$name}}DB(ctx, a.DB).Where("parent_path like ?", parentPath+"%").Update("status", status)
	return errors.WithStack(result.Error)
}
{{- end}}
{{- end}}