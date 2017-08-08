function List(){
  this._adverts = [];
}

List.prototype.add = function(advert){
  this._adverts.push(advert);
};

List.prototype.adverts = function(){
  return this._adverts;
};
