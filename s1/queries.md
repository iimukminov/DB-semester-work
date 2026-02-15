1) Выбрать логины тех работников, которые работают в пвз(Worker.pvz_id не равен 0)

$$
\pi _{Workers.login} (\sigma _{pvz\\_id\not\equiv0}(Workers))
$$

2) Получить список названий товаров, которые купил покупатель с логином "zombik"

$$
\pi_{Items.name} (
    \sigma_{(Buyers.login = "zombik")}Buyers
    \bowtie _{(Buyers.id = Purchases.buyer\\_id)}Purchases
    \bowtie_{(Purchases.item\\_id = Items.id)}Items
)
$$
