/* Schedul-ER Web Push service worker */
self.addEventListener('push',function(event){
  var data={title:'Schedul-ER',body:'You have a calendar update.',url:'/'};
  try{if(event.data){var incoming=event.data.json();data=Object.assign(data,incoming)}}catch(_){}
  event.waitUntil(self.registration.showNotification(data.title||'Schedul-ER',{
    body:data.body||'You have a calendar update.',icon:'/icons/icon.svg',badge:'/icons/icon.svg',
    tag:data.tag||'schedul-er-'+Date.now(),data:{url:data.url||'/'},renotify:false
  }));
});
self.addEventListener('notificationclick',function(event){
  event.notification.close();
  var target=new URL(event.notification.data&&event.notification.data.url||'/',self.location.origin).href;
  event.waitUntil(clients.matchAll({type:'window',includeUncontrolled:true}).then(function(list){
    for(var i=0;i<list.length;i++){
      if(new URL(list[i].url).origin===self.location.origin){list[i].focus();return list[i].navigate(target)}
    }
    return clients.openWindow(target);
  }));
});
