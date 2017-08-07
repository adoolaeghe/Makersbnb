function Advert (name) {
  this._name = name;
  this._isBooked = false;
}

Advert.prototype.name = function() {
  return this._name;
};

Advert.prototype.isBooked = function(){
  return this._isBooked;
};

Advert.prototype.book = function() {
  this._isBooked = true;
};
