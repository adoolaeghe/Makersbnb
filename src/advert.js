function Advert (name) {
  this._name = name;
}

Advert.prototype.name = function() {
  return this._name;
};
