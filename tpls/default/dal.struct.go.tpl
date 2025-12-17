package dal

import (
	"context"
	"fmt"
	"{{.ModuleImportPath}}/schema"
	"{{.RootImportPath}}/pkg/logging"
	"sync"

	"go.uber.org/zap"
	"gorm.io/gorm"
)

type {{.Name}} struct {
	DB *gorm.DB
	{{- if .MapKeyType }}
	cacheMap *sync.Map `wire:"-"`
	{{- end }}
}

{{- if .MapKeyType}}
func (a *{{.Name}}) cacheInit(ctx context.Context) {
	if a.cacheMap != nil {
		return
	}

    {{lowerCamel .Name}}QueryResult, err := a.Query(ctx, schema.{{.Name}}QueryParam{})
    if err != nil {
        logging.Context(ctx).Error("{{.Name}}.cacheInit Query error: ", zap.Error(err))
        return
    }

    for _, {{lowerCamel .Name}} := range {{lowerCamel .Name}}QueryResult.Data {
        a.cacheMap.Store({{lowerCamel .Name}}.TelegramId, {{lowerCamel .Name}})
    }

	a.cacheMap = &sync.Map{}
}

func (a *{{.Name}}) CacheGet(ctx context.Context, id {{.MapKeyType}}) *schema.{{.Name}} {
	a.cacheInit(ctx)
	value, ok := a.cacheMap.Load(id)
	if !ok {
		return &schema.{{.Name}}{}
	}

	return value.(*schema.{{.Name}})
}

func (a *{{.Name}}) CacheSet(ctx context.Context, {{lowerCamel .Name}} *schema.{{.Name}}) {
	a.cacheInit(ctx)
	a.cacheMap.Store({{.MapKeyFieldName}}, {{lowerCamel .Name}})
}

func (a *{{.Name}}) CacheRemove(ctx context.Context, id {{.MapKeyType}}) {
	a.cacheInit(ctx)
	a.cacheMap.Delete(id)
}

func (a *{{.Name}}) CacheRange(ctx context.Context, f func(key, value any) bool) {
	a.cacheInit(ctx)
	a.cacheMap.Range(f)
}
{{- end}}

func (a *{{.Name}}) whereX(ctx context.Context, db *gorm.DB, params *schema.{{.Name}}QueryParam, opts ...schema.{{.Name}}QueryOptions) (*gorm.DB, error) {
	return db, nil
}