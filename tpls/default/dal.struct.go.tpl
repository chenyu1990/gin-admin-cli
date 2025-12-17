package dal

import (
	"context"
	"time"
	"sync"

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

func (a *{{.Name}}) CacheSet(ctx context.Context, id {{.MapKeyType}}, user *schema.{{.Name}}) {
	a.cacheInit(ctx)
	a.cacheMap.Store(id, user)
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