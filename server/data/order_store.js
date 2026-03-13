let orders = [];

function listOrdersByUser(userId) {
  return orders
    .filter((order) => order.user_id === userId)
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
}

function addOrder(order) {
  orders.push(order);
  return order;
}

module.exports = {
  listOrdersByUser,
  addOrder,
};
