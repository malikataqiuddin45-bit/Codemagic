#!/bin/bash
set -e

mkdir -p app/screens

# 1) HomeScreen.js (gabungan index (1).php)
cat > app/screens/HomeScreen.js <<'JSX'
import React from "react";
import { ScrollView } from "react-native";
import HeaderBar from "../components/HeaderBar";
import Footer from "../components/Footer";
import HeroBanner from "../components/HeroBanner";
import ProductCarousel from "../components/ProductCarousel";

export default function HomeScreen() {
  return (
    <ScrollView style={{ flex: 1, backgroundColor: "#f2f2f2" }}>
      <HeaderBar />
      <HeroBanner />
      <ProductCarousel />
      {/* TODO: SpecialPrice, BannerAds, Blogs */}
      <Footer />
    </ScrollView>
  );
}
JSX

# 2) ProductScreen.js (ikut product.php)
cat > app/screens/ProductScreen.js <<'JSX'
import React from "react";
import { ScrollView, View, Text, FlatList, Image, StyleSheet } from "react-native";
import HeaderBar from "../components/HeaderBar";
import Footer from "../components/Footer";
import { products } from "../lib/functions";

export default function ProductScreen() {
  return (
    <ScrollView style={{ flex: 1, backgroundColor: "#f2f2f2" }}>
      <HeaderBar />
      <Text style={s.h}>Semua Produk</Text>
      <FlatList
        data={products}
        keyExtractor={(it) => it.id}
        numColumns={2}
        columnWrapperStyle={{ gap: 12 }}
        contentContainerStyle={{ padding: 12 }}
        renderItem={({ item }) => (
          <View style={s.card}>
            <Image source={{ uri: item.img }} style={s.img} />
            <Text style={s.title}>{item.title}</Text>
            <Text style={s.price}>RM {item.price}</Text>
          </View>
        )}
      />
      <Text style={s.h}>Top Sale</Text>
      <ProductCarousel />
      <Footer />
    </ScrollView>
  );
}

const s = StyleSheet.create({
  h: { fontSize: 18, fontWeight: "700", margin: 12 },
  card: {
    flex: 1,
    backgroundColor: "#fff",
    borderRadius: 8,
    marginBottom: 12,
    overflow: "hidden",
  },
  img: { width: "100%", height: 120, backgroundColor: "#eee" },
  title: { fontSize: 13, paddingHorizontal: 8, paddingTop: 6 },
  price: { fontSize: 14, fontWeight: "700", color: "#800000", padding: 8 },
});
JSX

echo "✅ Autopatch siap: HomeScreen.js & ProductScreen.js updated"
