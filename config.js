// 在 Supabase 建立專案、執行 schema.sql 後，填入以下公開設定。
// 注意：這裡只能放 Publishable Key (或舊版 anon key)，絕對不要放 secret/service_role key。
window.BREAD_CONFIG = {
  supabaseUrl: 'https://cxjgajuakhyfiupovejf.supabase.co',
  supabasePublishableKey:'sb_publishable_XX3kZgXeLmLhM3t9K4BSeQ_rBkuGggT',
  deliveryFee: 160, // 示例宅配運費，正式營業前自行調整
  products: [
    {id:'croissant',name:'經典奶油可頌',price:65,emoji:'🥐',description:'層層酥香，日常裡的小小奢侈。'},
    {id:'sourdough',name:'鄉村酸種麵包',price:180,emoji:'🍞',description:'長時間發酵，外脆內柔。'},
    {id:'bagel',name:'原味貝果',price:55,emoji:'🥯',description:'口感紮實，越嚼越香。'},
    {id:'roll',name:'海鹽奶油捲',price:60,emoji:'🥖',description:'鹹香奶油，溫柔回甘。'},
    {id:'toast',name:'北海道生吐司',price:180,emoji:'🍞',description:'柔軟細緻，早餐的好朋友。'},
    {id:'bun',name:'巧克力麵包',price:75,emoji:'🍫',description:'濃郁可可香氣，甜而不膩。'}
  ]
};
