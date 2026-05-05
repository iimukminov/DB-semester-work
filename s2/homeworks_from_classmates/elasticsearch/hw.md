### Шаг 1. Запуск Elasticsearch
```bash
docker run -d --name elasticsearch -p 9200:9200 -e "discovery.type=single-node" elasticsearch:7.17.22
```

*Проверить, что Elastic поднялся, можно командой: `curl localhost:9200`*

---

### Шаг 2. Создание индекса

Создадим индекс `products` и сразу зададим маппинг (типы данных), чтобы строгий поиск (`term`) работал корректно по полю `category`.

```json
PUT /products
{
  "mappings": {
    "properties": {
      "title": { "type": "text" },
      "category": { "type": "keyword" },
      "price": { "type": "double" },
      "in_stock": { "type": "boolean" }
    }
  }
}
```

```text
{
    "acknowledged": true,
    "shards_acknowledged": true,
    "index": "products"
}
```

---

### Шаг 3. Заполнение данными

Используем API `_bulk`, чтобы добавить сразу несколько документов за один запрос.

```json
POST /products/_bulk
{"index": {"_id": 1}}
{"title": "Умные часы Apple Watch", "category": "electronics", "price": 40000, "in_stock": true}
{"index": {"_id": 2}}
{"title": "Беспроводные наушники Sony", "category": "electronics", "price": 25000, "in_stock": true}
{"index": {"_id": 3}}
{"title": "Офисное кресло", "category": "furniture", "price": 15000, "in_stock": false}
{"index": {"_id": 4}}
{"title": "Умная колонка Яндекс", "category": "electronics", "price": 10000, "in_stock": true}
{"index": {"_id": 5}}
{"title": "Деревянный стол", "category": "furniture", "price": 20000, "in_stock": true}
```

```text
{
    "took": 24,
    "errors": false,
    "items": [
        {
            "index": {
                "_index": "products",
                "_type": "_doc",
                "_id": "1",
                "_version": 1,
                "result": "created",
                "_shards": {
                    "total": 2,
                    "successful": 1,
                    "failed": 0
                },
                "_seq_no": 0,
                "_primary_term": 1,
                "status": 201
            }
        },
        {
            "index": {
                "_index": "products",
                "_type": "_doc",
                "_id": "2",
                "_version": 1,
                "result": "created",
                "_shards": {
                    "total": 2,
                    "successful": 1,
                    "failed": 0
                },
                "_seq_no": 1,
                "_primary_term": 1,
                "status": 201
            }
        },
        {
            "index": {
                "_index": "products",
                "_type": "_doc",
                "_id": "3",
                "_version": 1,
                "result": "created",
                "_shards": {
                    "total": 2,
                    "successful": 1,
                    "failed": 0
                },
                "_seq_no": 2,
                "_primary_term": 1,
                "status": 201
            }
        },
        {
            "index": {
                "_index": "products",
                "_type": "_doc",
                "_id": "4",
                "_version": 1,
                "result": "created",
                "_shards": {
                    "total": 2,
                    "successful": 1,
                    "failed": 0
                },
                "_seq_no": 3,
                "_primary_term": 1,
                "status": 201
            }
        },
        {
            "index": {
                "_index": "products",
                "_type": "_doc",
                "_id": "5",
                "_version": 1,
                "result": "created",
                "_shards": {
                    "total": 2,
                    "successful": 1,
                    "failed": 0
                },
                "_seq_no": 4,
                "_primary_term": 1,
                "status": 201
            }
        }
    ]
}
```

---

### Шаг 4. Написание запросов

Согласно заданию, ниже представлены 4 разных запроса, покрывающие все требуемые операторы.

**Запрос 1: Поиск по названию (оператор `match`)**
Выполняет полнотекстовый поиск. Elastic разобьет слово на токены и найдет все товары, где в названии встречается слово "Умные" или "Умная".

```json
GET /products/_search
{
  "query": {
    "match": {
      "title": "Умная"
    }
  }
}
```

```text
{
    "took": 483,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 1,
            "relation": "eq"
        },
        "max_score": 1.3469357,
        "hits": [
            {
                "_index": "products",
                "_type": "_doc",
                "_id": "4",
                "_score": 1.3469357,
                "_source": {
                    "title": "Умная колонка Яндекс",
                    "category": "electronics",
                    "price": 10000,
                    "in_stock": true
                }
            }
        ]
    }
}
```

**Запрос 2: Точный поиск (оператор `term`)**
Используется для точного совпадения (без анализа текста). Отлично подходит для фильтрации по категориям, ID или статусам.

```json
GET /products/_search
{
  "query": {
    "term": {
      "category": "electronics"
    }
  }
}
```

```text
{
    "took": 3,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 3,
            "relation": "eq"
        },
        "max_score": 0.53899646,
        "hits": [
            {
                "_index": "products",
                "_type": "_doc",
                "_id": "1",
                "_score": 0.53899646,
                "_source": {
                    "title": "Умные часы Apple Watch",
                    "category": "electronics",
                    "price": 40000,
                    "in_stock": true
                }
            },
            {
                "_index": "products",
                "_type": "_doc",
                "_id": "2",
                "_score": 0.53899646,
                "_source": {
                    "title": "Беспроводные наушники Sony",
                    "category": "electronics",
                    "price": 25000,
                    "in_stock": true
                }
            },
            {
                "_index": "products",
                "_type": "_doc",
                "_id": "4",
                "_score": 0.53899646,
                "_source": {
                    "title": "Умная колонка Яндекс",
                    "category": "electronics",
                    "price": 10000,
                    "in_stock": true
                }
            }
        ]
    }
}
```

**Запрос 3: Поиск по диапазону (оператор `range`)**
Ищем товары, цена которых находится в заданном диапазоне (от 15 000 до 30 000 включительно).

```json
GET /products/_search
{
  "query": {
    "range": {
      "price": {
        "gte": 15000,
        "lte": 30000
      }
    }
  }
}
```

```text
{
    "took": 8,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 3,
            "relation": "eq"
        },
        "max_score": 1.0,
        "hits": [
            {
                "_index": "products",
                "_type": "_doc",
                "_id": "2",
                "_score": 1.0,
                "_source": {
                    "title": "Беспроводные наушники Sony",
                    "category": "electronics",
                    "price": 25000,
                    "in_stock": true
                }
            },
            {
                "_index": "products",
                "_type": "_doc",
                "_id": "3",
                "_score": 1.0,
                "_source": {
                    "title": "Офисное кресло",
                    "category": "furniture",
                    "price": 15000,
                    "in_stock": false
                }
            },
            {
                "_index": "products",
                "_type": "_doc",
                "_id": "5",
                "_score": 1.0,
                "_source": {
                    "title": "Деревянный стол",
                    "category": "furniture",
                    "price": 20000,
                    "in_stock": true
                }
            }
        ]
    }
}
```

**Запрос 4: Комбинированный запрос с фильтрами (оператор `bool`)**
Мощный запрос, который объединяет всё вместе. В блоке `must` (обязательно) мы делаем полнотекстовый поиск, а в блоке `filter` отсекаем результаты по точным значениям. *Фильтры не влияют на "вес" (score) документа и работают быстрее, так как кэшируются.*

```json
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "title": "часы наушники колонка" } }
      ],
      "filter": [
        { "term": { "in_stock": true } },
        { "range": { "price": { "lte": 30000 } } }
      ]
    }
  }
}
```

```text
{
    "took": 16,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 2,
            "relation": "eq"
        },
        "max_score": 1.3469357,
        "hits": [
            {
                "_index": "products",
                "_type": "_doc",
                "_id": "2",
                "_score": 1.3469357,
                "_source": {
                    "title": "Беспроводные наушники Sony",
                    "category": "electronics",
                    "price": 25000,
                    "in_stock": true
                }
            },
            {
                "_index": "products",
                "_type": "_doc",
                "_id": "4",
                "_score": 1.3469357,
                "_source": {
                    "title": "Умная колонка Яндекс",
                    "category": "electronics",
                    "price": 10000,
                    "in_stock": true
                }
            }
        ]
    }
}
```